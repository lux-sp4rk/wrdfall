import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { PrefetchManager } from '../prefetch.js';

describe('PrefetchManager', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
    // Use empty strings because import.meta.env stores strings only;
    // undefined would become the literal string "undefined", which breaks parseFloat.
    import.meta.env.VITE_GODOT_WASM = '';
    import.meta.env.VITE_GODOT_PCK = '';
    import.meta.env.VITE_GODOT_WASM_SIZE_MB = '';
    import.meta.env.VITE_GODOT_PCK_SIZE_MB = '';
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    import.meta.env.VITE_GODOT_WASM = '';
    import.meta.env.VITE_GODOT_PCK = '';
    import.meta.env.VITE_GODOT_WASM_SIZE_MB = '';
    import.meta.env.VITE_GODOT_PCK_SIZE_MB = '';
  });

  it.skip('should use default filenames when env vars are not set', () => {
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

  it('throws when wasm fetch returns non-ok response', async () => {
    import.meta.env.VITE_GODOT_WASM = 'missing';
    global.fetch.mockResolvedValue({
      ok: false,
      status: 404,
      headers: new Headers({}),
      body: null,
    });
    const manager = new PrefetchManager(() => {});
    await expect(manager.fetchGodotWasm()).rejects.toThrow('HTTP 404')
  });

  it('throws when pck fetch returns non-ok response', async () => {
    import.meta.env.VITE_GODOT_PCK = 'missing.pck';
    global.fetch.mockResolvedValue({
      ok: false,
      status: 500,
      headers: new Headers({}),
      body: null,
    });
    const manager = new PrefetchManager(() => {});
    await expect(manager.fetchGodotPck()).rejects.toThrow('HTTP 500')
  });

  it('reports progress during wasm download', async () => {
    import.meta.env.VITE_GODOT_WASM = 'progress-test';
    const progressValues = [];
    const manager = new PrefetchManager((p) => progressValues.push(p));

    global.fetch.mockResolvedValue({
      ok: true,
      headers: new Headers({ 'Content-Length': '100' }),
      body: {
        getReader: () => ({
          read: vi.fn()
            .mockResolvedValueOnce({ done: false, value: new Uint8Array(50) })
            .mockResolvedValueOnce({ done: false, value: new Uint8Array(50) })
            .mockResolvedValueOnce({ done: true })
        })
      }
    });

    await manager.fetchGodotWasm();
    expect(progressValues.length).toBeGreaterThan(0);
  });

  it('start() throws when one file fails', async () => {
    import.meta.env.VITE_GODOT_WASM = 'fail-wasm';
    global.fetch.mockImplementation((url) => {
      if (url.includes('fail-wasm')) {
        return Promise.resolve({ ok: false, status: 404, headers: new Headers({}), body: null });
      }
      return Promise.resolve({
        ok: true,
        headers: new Headers({ 'Content-Length': '10' }),
        body: {
          getReader: () => ({
            read: vi.fn().mockResolvedValueOnce({ done: true })
          })
        }
      });
    });

    const manager = new PrefetchManager(() => {});
    await expect(manager.start()).rejects.toThrow('Pre-fetch failed');
  });

  it('fetchDictionary marks dict progress as complete', async () => {
    const manager = new PrefetchManager(() => {});
    manager.compression = {
      fetchDictionary: vi.fn().mockResolvedValue('HELLO\nWORLD'),
    };
    await manager.fetchDictionary('en');
    expect(manager.downloads.dict.progress).toBe(1);
  });

  it('fetchDictionary throws with descriptive error', async () => {
    const manager = new PrefetchManager(() => {});
    manager.compression = {
      fetchDictionary: vi.fn().mockRejectedValue(new Error('Network error')),
    };
    await expect(manager.fetchDictionary('en')).rejects.toThrow('Dictionary fetch failed: Network error');
  });

  it('constructor initializes downloads with default sizes', () => {
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.wasm.size).toBe(33.7);
    expect(manager.downloads.pck.size).toBe(50.3);
    expect(manager.downloads.dict.size).toBe(2.6);
  });

  it('downloads dict size is always 2.6 regardless of env', () => {
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.dict.size).toBe(2.6);
  });

  it('fetchGodotWasm uses VITE_GODOT_WASM env var for filename', async () => {
    import.meta.env.VITE_GODOT_WASM = 'custom-wasm';
    global.fetch.mockResolvedValue({
      ok: true,
      headers: new Headers({ 'Content-Length': '10' }),
      body: { getReader: () => ({ read: vi.fn().mockResolvedValueOnce({ done: true }) }) }
    });
    const manager = new PrefetchManager(() => {});
    await manager.fetchGodotWasm();
    expect(global.fetch).toHaveBeenCalledWith('custom-wasm.wasm');
  });
});
