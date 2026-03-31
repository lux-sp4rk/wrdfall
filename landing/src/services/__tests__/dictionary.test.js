import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DictionaryManager } from '../dictionary.js';

describe('DictionaryManager', () => {
  let manager;

  beforeEach(() => {
    manager = new DictionaryManager();
    vi.stubGlobal('fetch', vi.fn());
  });

  describe('load', () => {
    it('validates language code format', async () => {
      await expect(manager.load('invalid')).rejects.toThrow('Invalid language code');
      await expect(manager.load('EN')).rejects.toThrow('Invalid language code');
      await expect(manager.load('english')).rejects.toThrow('Invalid language code');
    });

    it('returns cached dictionary', async () => {
      const words = new Set(['HELLO', 'WORLD']);
      manager.cache.set('en', words);

      const result = await manager.load('en');
      expect(result).toBe(words);
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('dedupes concurrent requests', async () => {
      let resolveFetch;
      global.fetch.mockImplementation(() => new Promise(resolve => {
        resolveFetch = resolve;
      }));

      const promise1 = manager.load('en');
      const promise2 = manager.load('en');

      expect(manager.loading.has('en')).toBe(true);

      // Resolve the fetch
      resolveFetch({
        ok: true,
        text: async () => 'HELLO\nWORLD',
      });

      const result1 = await promise1;
      const result2 = await promise2;

      expect(result1).toBe(result2); // Same reference
      expect(global.fetch).toHaveBeenCalledTimes(1);
    });

    it('fetches and parses dictionary from server', async () => {
      global.fetch.mockResolvedValue({
        ok: true,
        text: async () => 'HELLO\nWORLD\n#comment\n\nTEST',
      });

      const result = await manager.load('en');
      expect(result).toBeInstanceOf(Set);
      expect(result.has('HELLO')).toBe(true);
      expect(result.has('WORLD')).toBe(true);
      expect(result.has('TEST')).toBe(true);
      expect(result.has('#COMMENT')).toBe(false);
    });

    it('handles HTTP errors', async () => {
      global.fetch.mockResolvedValue({
        ok: false,
        status: 404,
      });

      await expect(manager.load('en')).rejects.toThrow("Failed to load dictionary for 'en'");
    });

    it('handles network errors', async () => {
      global.fetch.mockRejectedValue(new Error('Network failure'));

      await expect(manager.load('en')).rejects.toThrow('Network error loading en dictionary');
    });
  });

  describe('parseWords', () => {
    it('parses text into word set', () => {
      const text = 'hello\nworld\nHELLO\n#comment\n\n  spaced  ';
      const words = manager.parseWords(text);

      expect(words).toBeInstanceOf(Set);
      expect(words.has('HELLO')).toBe(true);
      expect(words.has('WORLD')).toBe(true);
      expect(words.has('SPACED')).toBe(true);
      expect(words.has('#COMMENT')).toBe(false);
    });

    it('handles empty text', () => {
      const words = manager.parseWords('');
      expect(words.size).toBe(0);
    });

    it('handles null text', () => {
      const words = manager.parseWords(null);
      expect(words.size).toBe(0);
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
