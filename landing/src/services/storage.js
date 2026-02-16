/**
 * StorageManager - LocalStorage + Supabase sync for high scores
 *
 * Strategy:
 * - Read from localStorage first (instant)
 * - Background sync with Supabase (non-blocking)
 * - Anonymous device IDs for MVP
 */

export class StorageManager {
  constructor(supabaseClient) {
    this.supabase = supabaseClient;
    this.localKey = 'word_loom_high_score';
    this.deviceIdKey = 'word_loom_device_id';
  }

  /**
   * Get high score for landing page teaser
   * Returns instantly from localStorage, syncs Supabase in background
   */
  async getHighScore() {
    // 1. Try localStorage first (instant)
    const local = this.getLocalHighScore();

    if (local !== null) {
      // Background sync from Supabase (don't await)
      this.syncFromSupabase().catch(err => {
        console.warn('Background sync failed:', err);
      });
      return local;
    }

    // 2. No local score, fetch from Supabase
    try {
      const remote = await this.fetchFromSupabase();
      if (remote !== null) {
        this.setLocalHighScore(remote);
        return remote;
      }
    } catch (error) {
      console.warn('Failed to fetch from Supabase:', error);
    }

    // 3. No score anywhere (new user)
    return null;
  }

  /**
   * Get high score from localStorage
   */
  getLocalHighScore() {
    const raw = localStorage.getItem(this.localKey);
    return raw ? parseInt(raw, 10) : null;
  }

  /**
   * Set high score in localStorage
   */
  setLocalHighScore(score) {
    localStorage.setItem(this.localKey, score.toString());
  }

  /**
   * Fetch high score from Supabase
   */
  async fetchFromSupabase() {
    const userId = this.getUserId();

    const { data, error } = await this.supabase
      .from('user_stats')
      .select('high_score')
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      return null;
    }

    return data.high_score;
  }

  /**
   * Background sync: update local if remote is higher
   */
  async syncFromSupabase() {
    const remote = await this.fetchFromSupabase();
    const local = this.getLocalHighScore();

    if (remote !== null && (local === null || remote > local)) {
      this.setLocalHighScore(remote);
    }
  }

  /**
   * Save high score (called from Godot via JS bridge)
   */
  async saveHighScore(score) {
    const currentHigh = this.getLocalHighScore() || 0;

    if (score <= currentHigh) {
      return; // Not a new high score
    }

    // Update local immediately
    this.setLocalHighScore(score);

    // Sync to Supabase (background, non-blocking)
    try {
      await this.supabase
        .from('user_stats')
        .upsert({
          user_id: this.getUserId(),
          high_score: score,
          updated_at: new Date().toISOString(),
        });
    } catch (error) {
      console.error('Failed to sync high score to Supabase:', error);
      // Non-critical: local score is saved
    }
  }

  /**
   * Get or create anonymous device ID
   */
  getUserId() {
    let deviceId = localStorage.getItem(this.deviceIdKey);
    if (!deviceId) {
      deviceId = crypto.randomUUID();
      localStorage.setItem(this.deviceIdKey, deviceId);
    }
    return deviceId;
  }
}
