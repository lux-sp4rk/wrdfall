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
    // Import Godot engine script
    const EngineLoader = await this._loadEngineScript();

    // Create engine instance
    this.engine = new EngineLoader({
      args: [],
      canvasResizePolicy: 2, // Adaptive
      executable: this.config.executable,
      experimentalVK: false,
      focusCanvas: true,
      gdextension: false,
    });

    // Create canvas
    this.canvas = document.createElement('canvas');
    this.canvas.id = 'godot-canvas';
    this.canvas.style.width = '100vw';
    this.canvas.style.height = '100vh';
    this.canvas.style.position = 'absolute';
    this.canvas.style.top = '0';
    this.canvas.style.left = '0';

    document.body.appendChild(this.canvas);

    // Set canvas on engine
    await this.engine.init(this.config.mainPack);
    this.engine.setCanvas(this.canvas);

    return this.engine;
  }

  /**
   * Start game with dictionary and settings
   */
  async start({ dictionary, settings }) {
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

    // Start Godot
    await this.engine.startGame();
  }

  /**
   * Load Godot engine script dynamically
   */
  async _loadEngineScript() {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = '/game/word-loom.js';
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
