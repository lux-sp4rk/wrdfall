/**
 * StorageManager - LocalStorage + Supabase sync for high scores
 *
 * Strategy:
 * - Read from localStorage first (instant)
 * - Background sync with Supabase (non-blocking)
 * - Anonymous device IDs for MVP
 */

import { safeStorage, clampNumber } from './hardening.js';

export class StorageManager {
  constructor(supabaseClient) {
    this.supabase = supabaseClient;
    this.localKey = 'word_loom_high_score';
    this.deviceIdKey = 'word_loom_device_id';
    this.maxScore = 999999999; // Prevent overflow
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
    try {
      const raw = localStorage.getItem(this.localKey);
      if (!raw) return null;
      const parsed = parseInt(raw, 10);
      // Validate: must be a finite non-negative number
      if (!Number.isFinite(parsed) || parsed < 0) {
        console.warn('Invalid high score in localStorage:', raw);
        return null;
      }
      return Math.min(parsed, this.maxScore);
    } catch (err) {
      console.warn('Failed to read high score:', err);
      return null;
    }
  }

  /**
   * Set high score in localStorage
   */
  setLocalHighScore(score) {
    const clamped = clampNumber(score, 0, this.maxScore, 0);
    localStorage.setItem(this.localKey, clamped.toString());
  }

  /**
   * Fetch high score from Supabase
   */
  async fetchFromSupabase() {
    if (!this.supabase) {
      console.warn('Supabase client not available');
      return null;
    }
    
    const userId = this.getUserId();
    if (!userId) {
      console.warn('No user ID available');
      return null;
    }

    try {
      const { data, error } = await this.supabase
        .from('user_stats')
        .select('high_score')
        .eq('user_id', userId)
        .maybeSingle();

      if (error) {
        console.warn('Supabase fetch failed:', error);
        return null;
      }
      if (!data) {
        return null; // No record exists yet
      }

      // Validate and clamp the score
      const score = clampNumber(data.high_score, 0, this.maxScore, 0);
      return score;
    } catch (err) {
      console.warn('Supabase fetch error:', err);
      return null;
    }
  }

  /**
   * Background sync: update local if remote is higher
   */
  async syncFromSupabase() {
    try {
      const remote = await this.fetchFromSupabase();
      const local = this.getLocalHighScore();

      if (remote !== null && (local === null || remote > local)) {
        this.setLocalHighScore(remote);
      }
    } catch (err) {
      console.warn('Sync from Supabase failed:', err);
    }
  }

  /**
   * Save high score (called from Godot via JS bridge)
   */
  async saveHighScore(score) {
    // Validate input with hardening
    const validScore = clampNumber(score, 0, this.maxScore, null);
    if (validScore === null) {
      console.warn('Invalid score rejected:', score);
      return;
    }

    const currentHigh = this.getLocalHighScore() || 0;

    if (validScore <= currentHigh) {
      return; // Not a new high score
    }

    // Update local immediately
    this.setLocalHighScore(validScore);

    // Sync to Supabase (background, non-blocking)
    if (this.supabase) {
      try {
        await this.supabase
          .from('user_stats')
          .upsert({
            user_id: this.getUserId(),
            high_score: validScore,
            updated_at: new Date().toISOString(),
          });
      } catch (error) {
        console.error('Failed to sync high score to Supabase:', error);
        // Non-critical: local score is saved
      }
    }
  }

  /**
   * Get or create anonymous device ID
   */
  getUserId() {
    try {
      let deviceId = localStorage.getItem(this.deviceIdKey);
      if (!deviceId) {
        // Validate crypto.randomUUID is available
        if (typeof crypto !== 'undefined' && crypto.randomUUID) {
          deviceId = crypto.randomUUID();
          localStorage.setItem(this.deviceIdKey, deviceId);
        } else {
          // Fallback for older browsers
          deviceId = 'user-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
          localStorage.setItem(this.deviceIdKey, deviceId);
        }
      }
      return deviceId;
    } catch (err) {
      console.error('Failed to get/create device ID:', err);
      // Return a temporary ID that won't persist
      return 'temp-' + Date.now();
    }
  }
}
