/**
 * PrefetchManager - Background download orchestration
 *
 * Downloads Godot engine files + English dictionary in parallel
 * Tracks progress for UI feedback
 */

import { CompressionService } from './compressionService.js';

export class PrefetchManager {
  constructor(onProgress) {
    this.onProgress = onProgress; // Callback: (progress: 0-100) => void
    this.compression = new CompressionService();
    // Sizes in MB — used as fallback when Content-Length header is missing.
    // Progress is capped at 1.0 to prevent > 100% display.
    this.downloads = {
      wasm: { 
        size: parseFloat(import.meta.env.VITE_GODOT_WASM_SIZE_MB || '33.7'), 
        progress: 0 
      },
      pck: { 
        size: parseFloat(import.meta.env.VITE_GODOT_PCK_SIZE_MB || '50.3'), 
        progress: 0 
      },
      dict: { size: 2.6, progress: 0 },
    };
  }

  /**
   * Start pre-fetch (parallel downloads including dictionary)
   */
  async start() {
    const results = await Promise.allSettled([
      this.fetchGodotWasm(),
      this.fetchGodotPck(),
      this.fetchDictionary('en'),
    ]);

    // Check for failures
    const failed = results
      .map((r, i) => ({ result: r, file: ['wasm', 'pck', 'dict'][i] }))
      .filter(({ result }) => result.status === 'rejected');

    if (failed.length > 0) {
      const details = failed.map(({ file, result }) =>
        `${file}: ${result.reason.message}`
      ).join(', ');
      throw new Error(`Pre-fetch failed: ${failed.length} file(s) - ${details}`);
    }

    return {
      wasmBlob: results[0].value,
      pckBlob: results[1].value,
      dict: results[2].value,
    };
  }

  /**
   * Fetch Godot Wasm with progress tracking
   */
  async fetchGodotWasm() {
    const filename = import.meta.env.VITE_GODOT_WASM || 'index';
    return this._fetchWithProgress(
      `${filename}.wasm`,
      'wasm'
    );
  }

  /**
   * Fetch Godot PCK with progress tracking
   */
  async fetchGodotPck() {
    const filename = import.meta.env.VITE_GODOT_PCK || 'index.pck';
    return this._fetchWithProgress(
      filename,
      'pck'
    );
  }

  /**
   * Fetch dictionary with progress tracking (decompression included)
   */
  async fetchDictionary(language) {
    try {
      const start = performance.now();
      const text = await this.compression.fetchDictionary(language);
      const elapsed = (performance.now() - start).toFixed(2);
      
      console.log(`📖 Dictionary '${language}' decompressed in ${elapsed}ms`);
      
      // Mark dict as complete
      this.downloads.dict.progress = 1;
      this._updateTotalProgress();
      
      return text;
    } catch (error) {
      throw new Error(`Dictionary fetch failed: ${error.message}`);
    }
  }

  /**
   * Fetch file with progress tracking
   */
  async _fetchWithProgress(url, key) {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${url}`);
    }

    const reader = response.body.getReader();
    const contentLength = +response.headers.get('Content-Length') || this.downloads[key].size * 1024 * 1024;

    let receivedLength = 0;
    const chunks = [];

    while (true) {
      const { done, value } = await reader.read();

      if (done) break;

      chunks.push(value);
      receivedLength += value.length;

      // Update progress — cap at 1.0 to prevent > 100% display
      this.downloads[key].progress = Math.min(1, receivedLength / contentLength);
      this._updateTotalProgress();
    }

    return new Blob(chunks);
  }

  /**
   * Calculate weighted total progress (WASM + PCK + Dict)
   */
  _updateTotalProgress() {
    const totalSize =
      this.downloads.wasm.size +
      this.downloads.pck.size +
      this.downloads.dict.size;

    const progress =
      (this.downloads.wasm.progress * this.downloads.wasm.size +
        this.downloads.pck.progress * this.downloads.pck.size +
        this.downloads.dict.progress * this.downloads.dict.size) /
      totalSize;

    this.onProgress(Math.min(100, Math.round(progress * 100)));
  }
}
