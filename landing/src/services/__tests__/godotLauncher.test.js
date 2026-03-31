import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { GodotLauncher } from '../godotLauncher.js';

describe('GodotLauncher', () => {
  let launcher;
  let mockEngine;

  beforeEach(() => {
    launcher = new GodotLauncher({
      executable: 'index.wasm',
      mainPack: 'index.pck',
      backgroundColor: '#2B3D4F',
    });

    // Mock Engine
    mockEngine = {
      init: vi.fn().mockResolvedValue(undefined),
      startGame: vi.fn().mockResolvedValue(undefined),
      requestQuit: vi.fn(),
    };

    // Add engine to window
    global.Engine = vi.fn().mockReturnValue(mockEngine);

    // Mock document methods
    vi.spyOn(document, 'createElement').mockImplementation((tag) => {
      if (tag === 'canvas') {
        return {
          style: {},
        };
      }
      if (tag === 'script') {
        return {
          onload: null,
          onerror: null,
          src: '',
        };
      }
      return {};
    });

    vi.spyOn(document.body, 'appendChild').mockImplementation(() => {});
    vi.spyOn(document.head, 'appendChild').mockImplementation((script) => {
      // Simulate script loading
      if (script.onload) {
        setTimeout(() => script.onload(), 0);
      }
    });

    // Clear window dictionary/settings
    delete window.WORD_LOOM_DICTIONARY;
    delete window.WORD_LOOM_SETTINGS;
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('initialize', () => {
    it('creates canvas and initializes engine', async () => {
      const engine = await launcher.initialize();

      expect(document.createElement).toHaveBeenCalledWith('canvas');
      expect(document.body.appendChild).toHaveBeenCalled();
      expect(global.Engine).toHaveBeenCalledWith(
        expect.objectContaining({
          executable: 'index',
          mainPack: 'index.pck',
          canvas: expect.any(Object),
        })
      );
      expect(mockEngine.init).toHaveBeenCalledWith('index');
      expect(engine).toBe(mockEngine);
    });

    it('strips .wasm extension from executable', async () => {
      launcher.config.executable = 'game.wasm';
      await launcher.initialize();

      expect(global.Engine).toHaveBeenCalledWith(
        expect.objectContaining({
          executable: 'game',
        })
      );
    });

    it('handles initialization errors', async () => {
      mockEngine.init.mockRejectedValue(new Error('Engine failed'));

      await expect(launcher.initialize()).rejects.toThrow(
        'Godot initialization failed'
      );
    });
  });

  describe('start', () => {
    beforeEach(async () => {
      await launcher.initialize();
    });

    it('validates dictionary input', async () => {
      await expect(
        launcher.start({ dictionary: null, settings: {} })
      ).rejects.toThrow('dictionary with words is required');
    });

    it('validates dictionary.words type', async () => {
      await expect(
        launcher.start({
          dictionary: { words: 'invalid', language: 'en' },
          settings: {},
        })
      ).rejects.toThrow('dictionary.words must be a Set or Array');
    });

    it('injects dictionary and settings into window', async () => {
      const dictionary = {
        language: 'en',
        words: ['HELLO', 'WORLD'],
      };
      const settings = { theme: 'dark' };

      await launcher.start({ dictionary, settings });

      expect(window.WORD_LOOM_DICTIONARY).toEqual({
        language: 'en',
        words: ['HELLO', 'WORLD'],
      });
      expect(window.WORD_LOOM_SETTINGS).toEqual({
        theme: 'dark',
        language: 'en',
      });
    });

    it('starts the game', async () => {
      const dictionary = {
        language: 'en',
        words: ['TEST'],
      };

      await launcher.start({ dictionary, settings: {} });

      expect(mockEngine.startGame).toHaveBeenCalledWith({
        mainPack: 'index.pck',
      });
    });

    it('handles game start errors', async () => {
      mockEngine.startGame.mockRejectedValue(new Error('Start failed'));

      await expect(
        launcher.start({
          dictionary: { words: ['TEST'], language: 'en' },
          settings: {},
        })
      ).rejects.toThrow('Game start failed');
    });
  });

  describe('stop', () => {
    it('stops engine and removes canvas', () => {
      // Setup
      const mockCanvas = document.createElement('canvas');
      mockCanvas.remove = vi.fn();
      launcher.canvas = mockCanvas;
      launcher.engine = mockEngine;

      launcher.stop();

      expect(mockEngine.requestQuit).toHaveBeenCalled();
      expect(mockCanvas.remove).toHaveBeenCalled();
      expect(launcher.engine).toBeNull();
      expect(launcher.canvas).toBeNull();
    });

    it('handles already stopped engine', () => {
      launcher.engine = {
        requestQuit: vi.fn().mockImplementation(() => {
          throw new Error('Already stopped');
        }),
      };
      launcher.canvas = { remove: vi.fn() };

      // Should not throw
      expect(() => launcher.stop()).not.toThrow();
    });
  });

  describe('_loadEngineScript', () => {
    it('loads engine script successfully', async () => {
      const loadPromise = launcher._loadEngineScript();

      // Wait for the promise to resolve
      const Engine = await loadPromise;
      expect(Engine).toBe(global.Engine);
    });

    it('rejects when script fails to load', async () => {
      document.head.appendChild.mockImplementation((script) => {
        if (script.onerror) {
          setTimeout(() => script.onerror(), 0);
        }
      });

      await expect(launcher._loadEngineScript()).rejects.toThrow(
        'Failed to load engine script'
      );
    });

    it('rejects when Engine not found on window', async () => {
      delete global.Engine;

      document.head.appendChild.mockImplementation((script) => {
        if (script.onload) {
          setTimeout(() => script.onload(), 0);
        }
      });

      await expect(launcher._loadEngineScript()).rejects.toThrow(
        'Engine not found on window'
      );
    });
  });

  describe('_delay', () => {
    it('delays for specified milliseconds', async () => {
      const start = Date.now();
      await launcher._delay(50);
      const elapsed = Date.now() - start;
      expect(elapsed).toBeGreaterThanOrEqual(45); // Allow small margin
    });
  });
});
