/**
 * CompressionService - Load and decompress dictionary files
 *
 * Strategy:
 * - Support gzip and brotli formats
 * - Prefer gzip for better browser support (DecompressionStream)
 * - Auto-detect format from file extension
 * - Cache decompressed data in memory
 * - Measure decompression time for logging
 */

export class CompressionService {
  constructor() {
    this.decompressed = new Map(); // cache for decompressed data
    this.pako = null; // lazy-loaded pako for gzip
    this.pakoLoadFailed = false; // track loading failures
  }

  /**
   * Lazy-load pako library for gzip decompression
   */
  async loadPako() {
    if (this.pako) return this.pako;
    if (this.pakoLoadFailed) {
      throw new Error('pako loading previously failed, not retrying');
    }
    
    try {
      const pako = await import('pako');
      this.pako = pako.default || pako;
      return this.pako;
    } catch (error) {
      this.pakoLoadFailed = true;
      const message = error?.message || String(error);
      console.error(`Failed to load pako: ${message}`);
      throw new Error(`Failed to load pako: ${message}`);
    }
  }

  /**
   * Fetch and decompress a dictionary file
   * Supports: .gz (gzip), .br (brotli), .txt (raw)
   * Prefers gzip for better browser compatibility
   */
  async fetchDictionary(language) {
    // Try formats in order of preference
    // Gzip first (widest support), then brotli, then raw
    const formats = [
      { ext: '.gz', decompress: async (data) => await this._decompressGzip(data) },
      { ext: '.br', decompress: async (data) => await this._decompressBrotli(data) },
      { ext: '.txt', decompress: async (data) => data } // raw format
    ];

    for (const { ext, decompress } of formats) {
      const url = `/dictionaries/${language}${ext}`;
      const cacheKey = `${language}${ext}`;

      // Check cache
      if (this.decompressed.has(cacheKey)) {
        return this.decompressed.get(cacheKey);
      }

      try {
        const start = performance.now();
        const response = await fetch(url);

        if (!response.ok) {
          continue; // Try next format
        }

        const buffer = await response.arrayBuffer();
        const decompressed = await decompress(new Uint8Array(buffer));
        const text = new TextDecoder().decode(decompressed);
        const elapsed = (performance.now() - start).toFixed(2);

        console.log(`📖 Loaded ${language}${ext} (${(buffer.byteLength / 1024).toFixed(2)} KB → decompressed in ${elapsed}ms)`);

        this.decompressed.set(cacheKey, text);
        return text;
      } catch (error) {
        const message = error?.message || String(error);
        console.warn(`Failed to load ${language}${ext}: ${message}`);
        continue;
      }
    }

    throw new Error(`Could not load dictionary for '${language}' in any format`);
  }

  /**
   * Decompress gzip data using pako library
   */
  async _decompressGzip(data) {
    const pako = await this.loadPako();
    try {
      return pako.inflate(data);
    } catch (error) {
      const message = error?.message || String(error);
      throw new Error(`Gzip decompression failed: ${message}`);
    }
  }

  /**
   * Decompress brotli data using native DecompressionStream
   * Falls back to error if not supported (don't silently return raw)
   */
  async _decompressBrotli(data) {
    try {
      const stream = new ReadableStream({
        start(controller) {
          controller.enqueue(data);
          controller.close();
        }
      });

      const decompressed = stream
        .pipeThrough(new DecompressionStream('br'));
      
      const reader = decompressed.getReader();
      const chunks = [];

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
      }

      // Combine chunks
      const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
      const result = new Uint8Array(totalLength);
      let offset = 0;
      for (const chunk of chunks) {
        result.set(chunk, offset);
        offset += chunk.length;
      }

      return result;
    } catch (error) {
      const message = error?.message || String(error);
      throw new Error(`Brotli decompression not supported in this browser: ${message}`);
    }
  }
}
