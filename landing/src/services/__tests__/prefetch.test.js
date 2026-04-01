import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { PrefetchManager } from '../prefetch.js';

describe('PrefetchManager', () => {
  let originalEnv;

  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
    // Store original env
    originalEnv = { ...import.meta.env };
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    // Restore original env
    Object.assign(import.meta.env, originalEnv);
  });

  it('should use default filenames when env vars are not set', () => {
    // Clear env vars
    delete import.meta.env.VITE_GODOT_WASM_SIZE_MB;
    delete import.meta.env.VITE_GODOT_PCK_SIZE_MB;
    
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.wasm.size).toBe(33.7);
    expect(manager.downloads.pck.size).toBe(50.3);
  });

  it('should use filenames from env vars when set', async () => {
    import.meta.env.VITE_GODOT_WASM = 'index.12345';
    import.meta.env.VITE_GODOT_PCK = 'index.12345.pck';
    
    const manager = new PrefetchManager(() => {});
    
    const mockResponse = {
      ok: true,
      headers: new Headers({ 'Content-Length': '100' }),
      body: {
        getReader: () => ({
          read: vi.fn()
            .mockResolvedValueOnce({ done: false, value: new Uint8Array(50) })
            .mockResolvedValueOnce({ done: true })
        })
      }
    };
    
    global.fetch.mockResolvedValue(mockResponse);

    await manager.fetchGodotWasm();
    expect(global.fetch).toHaveBeenCalledWith('index.12345.wasm');

    await manager.fetchGodotPck();
    expect(global.fetch).toHaveBeenCalledWith('index.12345.pck');
  });

  it('should use sizes from env vars when set', () => {
    import.meta.env.VITE_GODOT_WASM_SIZE_MB = '40.5';
    import.meta.env.VITE_GODOT_PCK_SIZE_MB = '60.2';
    
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.wasm.size).toBe(40.5);
    expect(manager.downloads.pck.size).toBe(60.2);
  });
});
