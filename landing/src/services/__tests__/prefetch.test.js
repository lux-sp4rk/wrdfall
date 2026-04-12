import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { PrefetchManager } from '../prefetch.js';
import { CompressionService } from '../compressionService.js';

describe('PrefetchManager', () => {
  let fetchMock;

  beforeEach(() => {
    fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);
    vi.unstubAllEnvs();
    vi.spyOn(CompressionService.prototype, 'fetchDictionary').mockResolvedValue('word1\nword2');
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it('should use default filenames when env vars are not set', () => {
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
    
    fetchMock.mockResolvedValue(mockResponse);

    await manager.fetchGodotWasm();
    expect(fetchMock).toHaveBeenCalledWith('index.12345.wasm');

    await manager.fetchGodotPck();
    expect(fetchMock).toHaveBeenCalledWith('index.12345.pck');
  });

  it('should use sizes from env vars when set', () => {
    vi.stubEnv('VITE_GODOT_WASM_SIZE_MB', '40.5');
    vi.stubEnv('VITE_GODOT_PCK_SIZE_MB', '60.2');
    
    const manager = new PrefetchManager(() => {});
    expect(manager.downloads.wasm.size).toBe(40.5);
    expect(manager.downloads.pck.size).toBe(60.2);
  });

  it('start() returns blobs when all downloads succeed', async () => {
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
    
    fetchMock.mockResolvedValue(mockResponse);

    const result = await manager.start();
    expect(result.wasmBlob).toBeInstanceOf(Blob);
    expect(result.pckBlob).toBeInstanceOf(Blob);
    expect(typeof result.dict).toBe('string');
  });

  it('start() throws when a download fails', async () => {
    const manager = new PrefetchManager(() => {});
    
    fetchMock.mockResolvedValue({
      ok: false,
      status: 404,
      body: { getReader: () => ({ read: vi.fn() }) }
    });

    await expect(manager.start()).rejects.toThrow('Pre-fetch failed');
  });

  it('_fetchWithProgress throws on non-ok response', async () => {
    const manager = new PrefetchManager(() => {});
    fetchMock.mockResolvedValue({
      ok: false,
      status: 500,
    });

    await expect(manager.fetchGodotWasm()).rejects.toThrow('HTTP 500');
  });
});
