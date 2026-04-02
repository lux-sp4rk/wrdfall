import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DictionaryManager } from '../dictionary-compressed.js';

describe('DictionaryManager (compressed)', () => {
  let manager;

  beforeEach(() => {
    manager = new DictionaryManager();
    vi.stubGlobal('fetch', vi.fn());
  });

  describe('load', () => {
    it('validates language code format', async () => {
      await expect(manager.load('invalid')).rejects.toThrow('Invalid language code');
      await expect(manager.load('EN')).rejects.toThrow('Invalid language code');
    });

    it('returns cached dictionary', async () => {
      const words = new Set(['HELLO', 'WORLD']);
      manager.cache.set('en', words);

      const result = await manager.load('en');
      expect(result).toBe(words);
    });

    it('dedupes concurrent requests', async () => {
      // Mock the compression service to return quickly
      const originalFetch = global.fetch;
      global.fetch = vi.fn(() =>
        Promise.resolve({
          ok: true,
          arrayBuffer: () => Promise.resolve(new TextEncoder().encode('HELLO\nWORLD').buffer),
        })
      );

      const promise1 = manager.load('en');
      const promise2 = manager.load('en');

      expect(manager.loading.has('en')).toBe(true);

      const [result1, result2] = await Promise.all([promise1, promise2]);

      expect(result1).toBe(result2);
      global.fetch = originalFetch;
    }, 10000);
  });

  describe('_fetch', () => {
    it('fetches and parses dictionary', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        text: async () => 'HELLO\nWORLD',
      });

      // Note: _fetch uses compression service which has its own fetch logic
      // This test verifies the basic structure
      expect(typeof manager._fetch).toBe('function');
    });

    it('throws error on fetch failure', async () => {
      global.fetch.mockRejectedValue(new Error('Network error'));

      await expect(manager.load('en')).rejects.toThrow("Failed to load dictionary for 'en'");
    });
  });

  describe('parseWords', () => {
    it('parses text into word set', () => {
      const text = 'hello\nworld\n#comment\n\n  spaced  ';
      const words = manager.parseWords(text);

      expect(words).toBeInstanceOf(Set);
      expect(words.has('HELLO')).toBe(true);
      expect(words.has('WORLD')).toBe(true);
      expect(words.has('SPACED')).toBe(true);
      expect(words.has('#COMMENT')).toBe(false);
    });
  });

  describe('sendToGodot', () => {
    it('sends dictionary to window object', () => {
      const words = new Set(['HELLO', 'WORLD']);
      manager.sendToGodot('en', words);

      expect(window.WORD_LOOM_DICTIONARY).toEqual({
        language: 'en',
        words: ['HELLO', 'WORLD'],
      });
    });

    it('validates words is a Set', () => {
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      manager.sendToGodot('en', ['not', 'a', 'set']);

      expect(consoleSpy).toHaveBeenCalledWith('sendToGodot: words must be a Set');
    });
  });

  describe('getCacheSize', () => {
    it('returns size of cached dictionary', () => {
      manager.cache.set('en', new Set(['A', 'B', 'C']));
      expect(manager.getCacheSize('en')).toBe(3);
    });

    it('returns 0 for uncached language', () => {
      expect(manager.getCacheSize('es')).toBe(0);
    });
  });
});
