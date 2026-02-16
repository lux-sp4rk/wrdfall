/**
 * DictionaryManager - Load and cache word dictionaries
 *
 * Strategy:
 * - English: Pre-fetch on page load
 * - Spanish: Lazy-load when user selects language
 * - In-memory cache (Map: language -> Set<word>)
 */

export class DictionaryManager {
  constructor() {
    this.cache = new Map(); // 'en' -> Set<string>
    this.loading = new Map(); // Track in-flight requests
  }

  /**
   * Load dictionary for given language
   * Returns cached if available, otherwise fetches
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
   * Fetch dictionary from server
   */
  async _fetch(language) {
    const url = `/game/dictionaries/${language}.txt`;
    try {
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`Failed to load dictionary for '${language}': HTTP ${response.status} from ${url}`);
      }

      const text = await response.text();

      // Parse into Set for fast lookups
      const words = new Set();
      const lines = text.split('\n');

      for (const line of lines) {
        const word = line.trim().toUpperCase();
        if (word && !word.startsWith('#')) {
          words.add(word);
        }
      }

      return words;
    } catch (error) {
      // Re-throw with context if this is a fetch/network error
      if (error.message.includes('Failed to load dictionary')) {
        throw error; // Already has context
      }
      throw new Error(`Network error loading ${language} dictionary: ${error.message}`);
    }
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
