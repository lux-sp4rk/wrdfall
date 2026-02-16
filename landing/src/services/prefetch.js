/**
 * PrefetchManager - Background download orchestration
 *
 * Downloads Godot engine files + English dictionary in parallel
 * Tracks progress for UI feedback
 */

export class PrefetchManager {
  constructor(onProgress) {
    this.onProgress = onProgress; // Callback: (progress: 0-100) => void
    this.downloads = {
      wasm: { size: 37, progress: 0 },
      pck: { size: 40, progress: 0 },
      dict: { size: 2.6, progress: 0 },
    };
  }

  /**
   * Start pre-fetch (parallel downloads)
   */
  async start() {
    const results = await Promise.allSettled([
      this.fetchGodotWasm(),
      this.fetchGodotPck(),
      this.fetchDictionary('en'),
    ]);

    // Check for failures
    const failed = results.filter(r => r.status === 'rejected');
    if (failed.length > 0) {
      throw new Error(`Pre-fetch failed: ${failed.length} file(s)`);
    }

    return {
      wasm: results[0].value,
      pck: results[1].value,
      dict: results[2].value,
    };
  }

  /**
   * Fetch Godot Wasm with progress tracking
   */
  async fetchGodotWasm() {
    return this._fetchWithProgress(
      '/game/word-loom.wasm',
      'wasm'
    );
  }

  /**
   * Fetch Godot PCK with progress tracking
   */
  async fetchGodotPck() {
    return this._fetchWithProgress(
      '/game/word-loom.pck',
      'pck'
    );
  }

  /**
   * Fetch dictionary with progress tracking
   */
  async fetchDictionary(language) {
    return this._fetchWithProgress(
      `/game/dictionaries/${language}.txt`,
      'dict'
    );
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

      // Update progress
      this.downloads[key].progress = receivedLength / contentLength;
      this._updateTotalProgress();
    }

    return new Blob(chunks);
  }

  /**
   * Calculate weighted total progress
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

    this.onProgress(Math.round(progress * 100));
  }
}
