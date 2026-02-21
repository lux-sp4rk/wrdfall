/**
 * GodotLauncher - Initialize and start Godot engine
 *
 * Handles:
 * - Canvas creation
 * - Engine initialization
 * - Dictionary injection
 * - Settings injection
 */

export class GodotLauncher {
  constructor(config) {
    this.config = config; // { executable, mainPack }
    this.engine = null;
    this.canvas = null;
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
      document.body.appendChild(this.canvas);

      // CRITICAL: Godot Engine.init() and the Engine config's `executable` field expect the
      // BASE NAME without any file extension. The engine internally appends '.wasm' when
      // fetching the binary. If we pass 'index.wasm', it fetches 'index.wasm.wasm' → 404 →
      // Netlify SPA redirect returns index.html → CompileError: expected magic word 00 61 73 6d,
      // found 3c 21 44 4f (i.e. '<!DO' = start of <!DOCTYPE html>).
      // See: https://github.com/lux-sp4rk/word-loom/issues/141
      const basePath = this.config.executable.replace(/\.wasm$/, '');

      // In Godot 4 JS API, canvas is passed in the config object — no setCanvas().
      this.engine = new Engine({
        args: [],
        canvas: this.canvas,
        canvasResizePolicy: 2,
        executable: basePath,
        experimentalVK: false,
        focusCanvas: true,
      });

      // Pass the base path (without .wasm) — Godot appends .wasm internally.
      await this.engine.init(basePath);

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
      // Inject dictionary into window
      window.WORD_LOOM_DICTIONARY = {
        language: dictionary.language,
        words: Array.from(dictionary.words),
      };

      // Inject settings
      window.WORD_LOOM_SETTINGS = {
        theme: settings.theme || 'light',
        language: dictionary.language,
      };

      // Start Godot — must pass mainPack so the engine knows where to find the PCK.
      await this.engine.startGame({ mainPack: this.config.mainPack });
    } catch (error) {
      console.error('Failed to start Godot game:', error);
      throw new Error(`Game start failed: ${error.message}`);
    }
  }

  /**
   * Load Godot engine script dynamically
   */
  async _loadEngineScript() {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'index.js';
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
}
