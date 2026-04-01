import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { CompressionService } from '../compressionService.js';

describe('CompressionService', () => {
  let service;

  beforeEach(() => {
    service = new CompressionService();
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  describe('loadPako', () => {
    it('loads pako library', async () => {
      const pako = await service.loadPako();
      expect(pako).toBeDefined();
      expect(service.pako).toBe(pako);
    });

    it('returns cached pako if already loaded', async () => {
      const pako1 = await service.loadPako();
      const pako2 = await service.loadPako();
      expect(pako1).toBe(pako2);
    });

    it('does not retry after load failure', async () => {
      // Simulate load failure by setting pakoLoadFailed flag
      service.pakoLoadFailed = true;
      await expect(service.loadPako()).rejects.toThrow('pako loading previously failed');
    });
  });

  describe('fetchDictionary', () => {
    it('returns cached dictionary if available', async () => {
      service.decompressed.set('en.br', 'cached dictionary');
      const result = await service.fetchDictionary('en');
      expect(result).toBe('cached dictionary');
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('fetches and caches raw text file', async () => {
      const mockText = 'word1\nword2\nword3';
      global.fetch.mockResolvedValue({
        ok: true,
        arrayBuffer: async () => new TextEncoder().encode(mockText).buffer,
      });

      const result = await service.fetchDictionary('en');
      expect(result).toBe(mockText);
      expect(service.decompressed.has('en.txt')).toBe(true);
    });

    it('tries multiple formats until one succeeds', async () => {
      // Brotli fails, gzip fails, raw succeeds
      global.fetch
        .mockResolvedValueOnce({ ok: false })
        .mockResolvedValueOnce({ ok: false })
        .mockResolvedValueOnce({
          ok: true,
          arrayBuffer: async () => new TextEncoder().encode('words').buffer,
        });

      const result = await service.fetchDictionary('en');
      expect(result).toBe('words');
      expect(global.fetch).toHaveBeenCalledTimes(3);
    });

    it('throws error when all formats fail', async () => {
      global.fetch.mockResolvedValue({ ok: false });

      await expect(service.fetchDictionary('en')).rejects.toThrow(
        "Could not load dictionary for 'en' in any format"
      );
    });
  });

  describe('_decompressGzip', () => {
    it('exists as a method', () => {
      expect(typeof service._decompressGzip).toBe('function');
    });
  });

  describe('_decompressBrotli', () => {
    it('exists as a method', () => {
      expect(typeof service._decompressBrotli).toBe('function');
    });
  });
});
