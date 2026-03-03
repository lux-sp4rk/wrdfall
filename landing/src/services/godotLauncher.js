/**
 * GodotLauncher - Initialize and start Godot engine
 *
 * Handles:
 * - Canvas creation
 * - Engine initialization
 * - Dictionary injection
 * - Settings injection
 * - JavaScriptBridge readiness check
 */

export class GodotLauncher {
  constructor(config) {
    this.config = config; // { executable, mainPack }
    this.engine = null;
    this.canvas = null;
    this.loader = null;
  }

  /**
   * Initialize Godot engine
   */
  async initialize() {
    try {
      // Import Godot engine script
      const Engine = await this._loadEngineScript();

      // Create canvas and append to DOM first
      this.canvas = document.createElement('canvas');
      this.canvas.id = 'godot-canvas';
      this.canvas.style.width = '100vw';
      this.canvas.style.height = '100vh';
      this.canvas.style.position = 'absolute';
      this.canvas.style.top = '0';
      this.canvas.style.left = '0';
      this.canvas.style.zIndex = '1';
      // Match letterbox bars to the theme background so they aren't black
      this.canvas.style.backgroundColor = this.config.backgroundColor || '#2B3D4F';
      document.body.appendChild(this.canvas);

      // Create loader overlay AFTER canvas so it stacks on top
      this._createLoader();

      // CRITICAL: Godot Engine.init() and the Engine config's `executable` field expect the
      // BASE NAME without any file extension. The engine internally appends '.wasm' when
      // fetching the binary. If we pass 'index.wasm', it fetches 'index.wasm.wasm' → 404 →
      // Netlify SPA redirect returns index.html → CompileError: expected magic word 00 61 73 6d,
      // found 3c 21 44 4f (i.e. '<!DO' = start of <!DOCTYPE html>).
      // See: https://github.com/lux-sp4rk/word-loom/issues/141
      const basePath = this.config.executable.replace(/\.wasm$/, '');
      const pckPath = this.config.mainPack || `${basePath}.pck`;

      // In Godot 4 JS API, canvas is passed in the config object — no setCanvas().
      // Added ensureCrossOriginIsolationHeaders and fileSizes to match Godot export exactly.
      this.engine = new Engine({
        args: [],
        canvas: this.canvas,
        canvasResizePolicy: 2,
        ensureCrossOriginIsolationHeaders: true,
        executable: basePath,
        mainPack: pckPath,
        experimentalVK: false,
        focusCanvas: true,
        fileSizes: {
          [`${basePath}.wasm`]: parseInt(import.meta.env.VITE_GODOT_WASM_SIZE || '35376909'),
          [`${pckPath}`]: parseInt(import.meta.env.VITE_GODOT_PCK_SIZE || '52786592'),
        },
      });

      // Pass the base path (without .wasm) — Godot appends .wasm internally.
      await this.engine.init(basePath);

      // CRITICAL: Add delay to allow Engine and JavaScriptBridge to fully initialize.
      // On deploy (especially Netlify), there's a race condition where Game.gd's Boot scene
      // fires _ready() before window.WORD_LOOM_DICTIONARY is available via JavaScriptBridge.
      // This 50ms delay ensures JavaScriptBridge is ready before startGame() is called.
      // See: https://github.com/lux-sp4rk/word-loom/issues/162
      await this._delay(50);
      console.log('✅ Engine initialized. JavaScriptBridge ready.');

      return this.engine;
    } catch (error) {
      console.error('Failed to initialize Godot engine:', error);
      throw new Error(`Godot initialization failed: ${error.message}`);
    }
  }

  /**
   * Start game with dictionary and settings
   */
  async start({ dictionary, settings }) {
    // Validate inputs
    if (!dictionary || !dictionary.words) {
      throw new Error('dictionary with words is required');
    }

    if (!(dictionary.words instanceof Set) && !Array.isArray(dictionary.words)) {
      throw new Error('dictionary.words must be a Set or Array');
    }

    try {
      // Convert to Array and create fast lookup Set
      const wordsArray = Array.from(dictionary.words);
      const wordCount = wordsArray.length;
      const wordSet = new Set(wordsArray.map(w => w.toLowerCase()));

      // Inject dictionary with lookup function (Godot-friendly)
      window.WORD_LOOM_DICTIONARY = {
        language: dictionary.language,
        words: wordsArray,
        // Godot can call this via JavaScriptBridge.eval()
        hasWord: function(word) {
          return wordSet.has(word.toLowerCase());
        }
      };

      console.log(`📖 Injected ${wordCount} words into window.WORD_LOOM_DICTIONARY`);

      // Inject settings
      window.WORD_LOOM_SETTINGS = {
        theme: settings.theme || 'light',
        language: dictionary.language,
      };

      console.log(`⚙️ Settings injected: ${JSON.stringify(window.WORD_LOOM_SETTINGS)}`);

      // Start Godot — must pass mainPack so the engine knows where to find the PCK.
      await this.engine.startGame({ mainPack: this.config.mainPack });

      // Game is now rendering — fade out and remove loader
      this._fadeOutLoader();
    } catch (error) {
      console.error('Failed to start Godot game:', error);
      throw new Error(`Game start failed: ${error.message}`);
    }
  }

  /**
   * Stop the engine and remove the canvas from the DOM.
   */
  stop() {
    if (this.engine) {
      try {
        this.engine.requestQuit();
      } catch (_) {
        // Engine may already be stopped
      }
      this.engine = null;
    }
    if (this.canvas) {
      this.canvas.remove();
      this.canvas = null;
    }
    this._removeLoader();
  }

  /**
   * Load Godot engine script dynamically
   */
  async _loadEngineScript() {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      const filename = import.meta.env.VITE_GODOT_JS || 'index';
      script.src = `${filename}.js`;
      script.onload = () => {
        if (window.Engine) {
          resolve(window.Engine);
        } else {
          reject(new Error('Engine not found on window'));
        }
      };
      script.onerror = () => reject(new Error('Failed to load engine script'));
      document.head.appendChild(script);
    });
  }

  /**
   * Helper: Sleep for N milliseconds
   */
  _delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Create loading overlay
   */
  _createLoader() {
    console.log('[GodotLauncher] Creating loader...');
    this.loader = document.createElement('div');
    this.loader.id = 'godot-loader';
    // Use inline styles to ensure visibility regardless of CSS variable availability
    this.loader.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background-color: #2B3D4F;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      z-index: 9999;
    `;
    this.loader.innerHTML = `
      <div style="
        width: 48px;
        height: 48px;
        border: 4px solid #4D6B8A;
        border-top-color: #F29170;
        border-radius: 50%;
        animation: godot-spin 1s linear infinite;
      "></div>
      <div style="
        margin-top: 16px;
        font-family: Inter, -apple-system, BlinkMacSystemFont, sans-serif;
        font-size: 16px;
        font-weight: 500;
        color: #F2F2F2;
        letter-spacing: 0.3px;
      ">Loading game…</div>
    `;
    document.body.appendChild(this.loader);
    console.log('[GodotLauncher] Loader appended to body');

    // Inject keyframes for spinner animation
    if (!document.getElementById('godot-loader-styles')) {
      const style = document.createElement('style');
      style.id = 'godot-loader-styles';
      style.textContent = `
        @keyframes godot-spin {
          to { transform: rotate(360deg); }
        }
        @keyframes godot-fade-out {
          from { opacity: 1; }
          to { opacity: 0; }
        }
      `;
      document.head.appendChild(style);
    }
  }

  /**
   * Remove loading overlay
   */
  _removeLoader() {
    if (this.loader) {
      console.log('[GodotLauncher] Removing loader from DOM');
      this.loader.remove();
      this.loader = null;
    }
  }

  /**
   * Fade out and remove loader after game starts
   */
  _fadeOutLoader() {
    if (!this.loader) return;
    console.log('[GodotLauncher] Fading out loader...');

    // Use inline animation for fade-out
    this.loader.style.animation = 'godot-fade-out 300ms ease-out forwards';

    // Remove from DOM after animation completes
    setTimeout(() => {
      this._removeLoader();
    }, 350); // Slightly longer than CSS animation (300ms)
  }
}
