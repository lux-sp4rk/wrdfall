/**
 * PrefetchManager - Background download orchestration
 *
 * Downloads Godot engine files + English dictionary in parallel
 * Tracks progress for UI feedback
 */

export class PrefetchManager {
  constructor(onProgress) {
    this.onProgress = onProgress; // Callback: (progress: 0-100) => void
    // Sizes in MB — used as fallback when Content-Length header is missing.
    // Progress is capped at 1.0 to prevent > 100% display.
    this.downloads = {
      wasm: { size: 37.686, progress: 0 },
      pck: { size: 58.2, progress: 0 },
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
    ]);

    // Check for failures
    const failed = results
      .map((r, i) => ({ result: r, file: ['wasm', 'pck'][i] }))
      .filter(({ result }) => result.status === 'rejected');

    if (failed.length > 0) {
      const details = failed.map(({ file, result }) =>
        `${file}: ${result.reason.message}`
      ).join(', ');
      throw new Error(`Pre-fetch failed: ${failed.length} file(s) - ${details}`);
    }

    return {
      wasm: results[0].value,
      pck: results[1].value,
    };
  }

  /**
   * Fetch Godot Wasm with progress tracking
   */
  async fetchGodotWasm() {
    return this._fetchWithProgress(
      'index.wasm',
      'wasm'
    );
  }

  /**
   * Fetch Godot PCK with progress tracking
   */
  async fetchGodotPck() {
    return this._fetchWithProgress(
      'index.pck',
      'pck'
    );
  }

  /**
   * Fetch dictionary with progress tracking
   */
  async fetchDictionary(language) {
    return this._fetchWithProgress(
      `dictionaries/${language}.txt`,
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

      // Update progress — cap at 1.0 to prevent > 100% display
      this.downloads[key].progress = Math.min(1, receivedLength / contentLength);
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
      this.downloads.pck.size;

    const progress =
      (this.downloads.wasm.progress * this.downloads.wasm.size +
        this.downloads.pck.progress * this.downloads.pck.size) /
      totalSize;

    this.onProgress(Math.min(100, Math.round(progress * 100)));
  }
}
