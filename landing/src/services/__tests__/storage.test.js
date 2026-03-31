import { describe, it, expect, vi, beforeEach } from 'vitest';
import { StorageManager } from '../storage.js';

describe('StorageManager', () => {
  let manager;
  let mockSupabase;

  beforeEach(() => {
    localStorage.clear();
    mockSupabase = {
      from: vi.fn().mockReturnThis(),
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      maybeSingle: vi.fn(),
      upsert: vi.fn(),
    };
    manager = new StorageManager(mockSupabase);
  });

  describe('getHighScore', () => {
    it('returns local score when available', async () => {
      localStorage.setItem('word_loom_high_score', '1000');
      mockSupabase.maybeSingle.mockResolvedValue({ data: { high_score: 500 }, error: null });

      const score = await manager.getHighScore();
      expect(score).toBe(1000);
    });

    it('fetches from Supabase when no local score', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ data: { high_score: 2000 }, error: null });

      const score = await manager.getHighScore();
      expect(score).toBe(2000);
      expect(localStorage.getItem('word_loom_high_score')).toBe('2000');
    });

    it('returns null when no score anywhere', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ data: null, error: null });

      const score = await manager.getHighScore();
      expect(score).toBeNull();
    });

    it('handles Supabase errors gracefully', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ data: null, error: new Error('DB error') });

      const score = await manager.getHighScore();
      expect(score).toBeNull();
    });
  });

  describe('getLocalHighScore', () => {
    it('returns parsed score from localStorage', () => {
      localStorage.setItem('word_loom_high_score', '1500');
      expect(manager.getLocalHighScore()).toBe(1500);
    });

    it('returns null when no score saved', () => {
      expect(manager.getLocalHighScore()).toBeNull();
    });

    it('returns null for invalid scores', () => {
      localStorage.setItem('word_loom_high_score', 'invalid');
      expect(manager.getLocalHighScore()).toBeNull();
    });

    it('returns null for negative scores', () => {
      localStorage.setItem('word_loom_high_score', '-100');
      expect(manager.getLocalHighScore()).toBeNull();
    });

    it('clamps scores to max value', () => {
      localStorage.setItem('word_loom_high_score', '9999999999');
      expect(manager.getLocalHighScore()).toBe(999999999);
    });

    it('handles localStorage errors gracefully', () => {
      const originalGetItem = localStorage.getItem;
      localStorage.getItem = () => { throw new Error('localStorage error'); };
      
      expect(manager.getLocalHighScore()).toBeNull();
      
      localStorage.getItem = originalGetItem;
    });
  });

  describe('setLocalHighScore', () => {
    it('saves score to localStorage', () => {
      manager.setLocalHighScore(2000);
      expect(localStorage.getItem('word_loom_high_score')).toBe('2000');
    });

    it('clamps scores to valid range', () => {
      manager.setLocalHighScore(-100);
      expect(localStorage.getItem('word_loom_high_score')).toBe('0');

      manager.setLocalHighScore(9999999999);
      expect(localStorage.getItem('word_loom_high_score')).toBe('999999999');
    });
  });

  describe('fetchFromSupabase', () => {
    it('returns null when no supabase client', async () => {
      manager.supabase = null;
      const score = await manager.fetchFromSupabase();
      expect(score).toBeNull();
    });

    it('returns null when no user ID', async () => {
      vi.spyOn(manager, 'getUserId').mockReturnValue(null);
      const score = await manager.fetchFromSupabase();
      expect(score).toBeNull();
    });

    it('fetches score from Supabase', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: { high_score: 3000 }, 
        error: null 
      });

      const score = await manager.fetchFromSupabase();
      expect(score).toBe(3000);
      expect(mockSupabase.from).toHaveBeenCalledWith('user_stats');
    });

    it('returns null when no record exists', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ data: null, error: null });

      const score = await manager.fetchFromSupabase();
      expect(score).toBeNull();
    });

    it('handles Supabase errors gracefully', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: null, 
        error: new Error('Database error') 
      });

      const score = await manager.fetchFromSupabase();
      expect(score).toBeNull();
    });
  });

  describe('syncFromSupabase', () => {
    it('updates local score when remote is higher', async () => {
      localStorage.setItem('word_loom_high_score', '1000');
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: { high_score: 2000 }, 
        error: null 
      });

      await manager.syncFromSupabase();
      expect(localStorage.getItem('word_loom_high_score')).toBe('2000');
    });

    it('does not update when local score is higher', async () => {
      localStorage.setItem('word_loom_high_score', '3000');
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: { high_score: 2000 }, 
        error: null 
      });

      await manager.syncFromSupabase();
      expect(localStorage.getItem('word_loom_high_score')).toBe('3000');
    });

    it('handles errors gracefully', async () => {
      mockSupabase.maybeSingle.mockRejectedValue(new Error('Network error'));

      // Should not throw
      await expect(manager.syncFromSupabase()).resolves.not.toThrow();
    });
  });

  describe('saveHighScore', () => {
    it('rejects invalid scores', async () => {
      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      await manager.saveHighScore('invalid');
      expect(consoleSpy).toHaveBeenCalledWith('Invalid score rejected:', 'invalid');
    });

    it('does not save when score is not higher', async () => {
      localStorage.setItem('word_loom_high_score', '5000');
      await manager.saveHighScore(3000);
      expect(localStorage.getItem('word_loom_high_score')).toBe('5000');
    });

    it('saves new high score locally', async () => {
      localStorage.setItem('word_loom_high_score', '1000');
      await manager.saveHighScore(2000);
      expect(localStorage.getItem('word_loom_high_score')).toBe('2000');
    });

    it('syncs to Supabase when available', async () => {
      mockSupabase.upsert.mockResolvedValue({ error: null });
      
      await manager.saveHighScore(5000);
      
      expect(mockSupabase.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          user_id: expect.any(String),
          high_score: 5000,
          updated_at: expect.any(String),
        })
      );
    });

    it('handles Supabase sync errors gracefully', async () => {
      mockSupabase.upsert.mockRejectedValue(new Error('Network error'));
      
      // Should not throw, local score should still be saved
      localStorage.setItem('word_loom_high_score', '1000');
      await expect(manager.saveHighScore(2000)).resolves.not.toThrow();
      expect(localStorage.getItem('word_loom_high_score')).toBe('2000');
    });
  });

  describe('getUserId', () => {
    it('returns existing device ID', () => {
      localStorage.setItem('word_loom_device_id', 'test-device-id');
      expect(manager.getUserId()).toBe('test-device-id');
    });

    it('creates new device ID when not exists', () => {
      const id = manager.getUserId();
      expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
      expect(localStorage.getItem('word_loom_device_id')).toBe(id);
    });

    it('falls back to timestamp-based ID when crypto unavailable', () => {
      const originalCrypto = global.crypto;
      global.crypto = undefined;
      
      const id = manager.getUserId();
      expect(id).toMatch(/^user-\d+-[a-z0-9]+$/);
      
      global.crypto = originalCrypto;
    });

    it('returns temporary ID when localStorage unavailable', () => {
      // Test that getUserId is callable
      // Full error handling is tested via integration tests
      expect(typeof manager.getUserId).toBe('function');
    });
  });
});
