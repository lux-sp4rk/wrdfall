import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { PrefetchManager } from '../prefetch.js';

describe('PrefetchManager', () => {
  const originalEnv = { ...import.meta.env };

  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
    // Reset env for each test
    import.meta.env.VITE_GODOT_WASM = undefined;
    import.meta.env.VITE_GODOT_PCK = undefined;
    import.meta.env.VITE_GODOT_WASM_SIZE_MB = undefined;
    import.meta.env.VITE_GODOT_PCK_SIZE_MB = undefined;
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    // Restore env
    Object.assign(import.meta.env, originalEnv);
  });

  it.skip('should use default filenames when env vars are not set', () => {
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.wasm.size).toBe(33.7);
    expect(manager.downloads.pck.size).toBe(50.3);
  });

  it('should use filenames from env vars when set', async () => {
    vi.stubEnv('VITE_GODOT_WASM', 'index.12345');
    vi.stubEnv('VITE_GODOT_PCK', 'index.12345.pck');
    
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
    vi.stubEnv('VITE_GODOT_WASM_SIZE_MB', '40.5');
    vi.stubEnv('VITE_GODOT_PCK_SIZE_MB', '60.2');
    
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.wasm.size).toBe(40.5);
    expect(manager.downloads.pck.size).toBe(60.2);
  });
});
