/**
 * DictionaryManager - Load and cache word dictionaries with compression support
 *
 * Strategy:
 * - English: Pre-fetch on page load (try compressed .gz/.br first, fallback to .txt)
 * - Spanish: Lazy-load when user selects language
 * - In-memory cache (Map: language -> Set<word>)
 * - Automatically try compressed formats (.br, .gz) before raw .txt
 */

import { CompressionService } from './compressionService.js';

export class DictionaryManager {
  constructor() {
    this.cache = new Map(); // 'en' -> Set<string>
    this.loading = new Map(); // Track in-flight requests
    this.compression = new CompressionService();
  }

  /**
   * Load dictionary for given language
   * Returns cached if available, otherwise fetches (tries compressed formats first)
   */
  async load(language = 'en') {
    // Validate language code (2-letter ISO 639-1)
    if (!/^[a-z]{2}$/.test(language)) {
      throw new Error(`Invalid language code: ${language}`);
    }

    // Check in-memory cache
    if (this.cache.has(language)) {
      return this.cache.get(language);
    }

    // Dedupe concurrent requests
    if (this.loading.has(language)) {
      return this.loading.get(language);
    }

    // Fetch and parse
    const promise = this._fetch(language);
    this.loading.set(language, promise);

    try {
      const words = await promise;
      this.cache.set(language, words);
      return words;
    } finally {
      this.loading.delete(language);
    }
  }

  /**
   * Fetch dictionary from server (tries compressed formats first)
   */
  async _fetch(language) {
    try {
      // Try compression service first (supports .br, .gz, .txt)
      const text = await this.compression.fetchDictionary(language);
      return this._parseWords(text);
    } catch (error) {
      // Re-throw with context
      throw new Error(`Failed to load dictionary for '${language}': ${error.message}`);
    }
  }

  /**
   * Parse dictionary text into Set for fast lookups
   */
  _parseWords(text) {
    const words = new Set();
    const lines = text.split('\n');

    for (const line of lines) {
      const word = line.trim().toUpperCase();
      if (word && !word.startsWith('#')) {
        words.add(word);
      }
    }

    return words;
  }

  /**
   * Send dictionary to Godot via window object
   */
  sendToGodot(language, words) {
    if (!(words instanceof Set)) {
      console.error('sendToGodot: words must be a Set');
      return;
    }
    window.WORD_LOOM_DICTIONARY = {
      language,
      words: Array.from(words),
    };
  }

  /**
   * Get cached dictionary size (for debugging)
   */
  getCacheSize(language) {
    const words = this.cache.get(language);
    return words ? words.size : 0;
  }
}
