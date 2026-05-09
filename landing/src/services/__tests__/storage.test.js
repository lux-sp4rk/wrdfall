import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { StorageManager } from '../storage.js'

describe('StorageManager', () => {
  let storage
  let mockSupabase

  beforeEach(() => {
    localStorage.clear()
    mockSupabase = {
      from: vi.fn().mockReturnThis(),
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
      upsert: vi.fn().mockResolvedValue({ error: null }),
    }
    storage = new StorageManager(mockSupabase)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('constructor', () => {
    it('creates storage manager instance', () => {
      expect(storage).toBeInstanceOf(StorageManager)
    })

    it('initializes with supabase client', () => {
      expect(storage.supabase).toBe(mockSupabase)
    })
  })

  describe('getLocalHighScore', () => {
    it('returns null when no score exists', () => {
      expect(storage.getLocalHighScore()).toBeNull()
    })

    it('returns parsed score from localStorage', () => {
      localStorage.setItem('word_loom_high_score', '12345')
      expect(storage.getLocalHighScore()).toBe(12345)
    })

    it('clamps score to maximum', () => {
      localStorage.setItem('word_loom_high_score', '9999999999')
      expect(storage.getLocalHighScore()).toBe(999999999)
    })

    it('returns null for invalid numbers', () => {
      localStorage.setItem('word_loom_high_score', 'invalid')
      expect(storage.getLocalHighScore()).toBeNull()
    })

    it('returns null for negative numbers', () => {
      localStorage.setItem('word_loom_high_score', '-100')
      expect(storage.getLocalHighScore()).toBeNull()
    })

    it('handles localStorage errors gracefully', () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new Error('Storage access denied')
      })
      
      expect(storage.getLocalHighScore()).toBeNull()
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })

  describe('setLocalHighScore', () => {
    it('saves score to localStorage', () => {
      storage.setLocalHighScore(5000)
      expect(localStorage.getItem('word_loom_high_score')).toBe('5000')
    })

    it('clamps score to maximum', () => {
      storage.setLocalHighScore(9999999999)
      expect(localStorage.getItem('word_loom_high_score')).toBe('999999999')
    })

    it('clamps negative scores to 0', () => {
      storage.setLocalHighScore(-100)
      expect(localStorage.getItem('word_loom_high_score')).toBe('0')
    })
  })

  describe('getHighScore', () => {
    it('returns local score when available', async () => {
      localStorage.setItem('word_loom_high_score', '1000')
      const score = await storage.getHighScore()
      expect(score).toBe(1000)
    })

    it('fetches from Supabase when no local score', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: { high_score: 2000 }, 
        error: null 
      })
      
      const score = await storage.getHighScore()
      expect(score).toBe(2000)
      expect(localStorage.getItem('word_loom_high_score')).toBe('2000')
    })

    it('returns null when no score anywhere', async () => {
      const score = await storage.getHighScore()
      expect(score).toBeNull()
    })

    it('handles Supabase errors gracefully', async () => {
      mockSupabase.maybeSingle.mockRejectedValue(new Error('Network error'))
      
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      const score = await storage.getHighScore()
      
      expect(score).toBeNull()
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })

  describe('fetchFromSupabase', () => {
    it('returns null when no supabase client', async () => {
      storage.supabase = null
      const score = await storage.fetchFromSupabase()
      expect(score).toBeNull()
    })

    it('fetches score from Supabase', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: { high_score: 5000 }, 
        error: null 
      })
      
      const score = await storage.fetchFromSupabase()
      expect(score).toBe(5000)
    })

    it('returns null on Supabase error', async () => {
      mockSupabase.maybeSingle.mockResolvedValue({ 
        data: null, 
        error: { message: 'DB error' } 
      })
      
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      const score = await storage.fetchFromSupabase()
      
      expect(score).toBeNull()
      
      spy.mockRestore()
    })
  })

  describe('saveHighScore', () => {
    it('does nothing when score is not higher', async () => {
      localStorage.setItem('word_loom_high_score', '5000')
      await storage.saveHighScore(4000)
      
      expect(localStorage.getItem('word_loom_high_score')).toBe('5000')
    })

    it('saves new high score locally', async () => {
      await storage.saveHighScore(6000)
      expect(localStorage.getItem('word_loom_high_score')).toBe('6000')
    })

    it('syncs to Supabase when available', async () => {
      await storage.saveHighScore(7000)
      
      expect(mockSupabase.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          high_score: 7000,
        })
      )
    })

    it('rejects invalid scores', async () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      await storage.saveHighScore('invalid')
      
      expect(localStorage.getItem('word_loom_high_score')).toBeNull()
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })

  describe('saveSessionStats', () => {
    it('saves first session stats to word-loom-stats', async () => {
      const session = {
        score: 1000,
        wordsFound: 5,
        tilesCleared: 20,
        duration: 120,
        longestWord: 'hello',
      }
      storage.saveSessionStats(session)

      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.high_score).toBe(1000)
      expect(saved.longest_word).toBe('hello')
      expect(saved.total_words).toBe(5)
      expect(saved.total_tiles).toBe(20)
      expect(saved.total_time).toBe(120)
      expect(saved.session_history).toHaveLength(1)
      expect(saved.session_history[0].score).toBe(1000)
    })

    it('accumulates totals across sessions', async () => {
      storage.saveSessionStats({ score: 1000, wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'hello' })
      storage.saveSessionStats({ score: 800, wordsFound: 3, tilesCleared: 15, duration: 60, longestWord: 'hi' })

      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.total_words).toBe(8)
      expect(saved.total_tiles).toBe(35)
      expect(saved.total_time).toBe(180)
    })

    it('updates high score when new score is higher', async () => {
      storage.saveSessionStats({ score: 1000, wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'hello' })
      storage.saveSessionStats({ score: 1500, wordsFound: 3, tilesCleared: 15, duration: 60, longestWord: 'yo' })

      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.high_score).toBe(1500)
    })

    it('keeps existing high score when new score is lower', async () => {
      storage.saveSessionStats({ score: 1000, wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'hello' })
      storage.saveSessionStats({ score: 500, wordsFound: 3, tilesCleared: 15, duration: 60, longestWord: 'yo' })

      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.high_score).toBe(1000)
    })

    it('updates longest word when new word is longer', async () => {
      storage.saveSessionStats({ score: 1000, wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'hello' })
      storage.saveSessionStats({ score: 800, wordsFound: 3, tilesCleared: 15, duration: 60, longestWord: 'superlong' })

      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.longest_word).toBe('superlong')
    })

    it('keeps existing longest word when new word is shorter', async () => {
      storage.saveSessionStats({ score: 1000, wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'superlong' })
      storage.saveSessionStats({ score: 800, wordsFound: 3, tilesCleared: 15, duration: 60, longestWord: 'hi' })

      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.longest_word).toBe('superlong')
    })

    it('caps session_history at 50 records', async () => {
      for (let i = 0; i < 60; i++) {
        storage.saveSessionStats({ score: i, wordsFound: 1, tilesCleared: 1, duration: 10, longestWord: 'word' })
      }
      const saved = JSON.parse(localStorage.getItem('word-loom-stats'))
      expect(saved.session_history).toHaveLength(50)
      expect(saved.session_history[0].score).toBe(59) // most recent first
    })

    it('rejects invalid scores', async () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      storage.saveSessionStats({ score: 'invalid', wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'hello' })

      expect(localStorage.getItem('word-loom-stats')).toBeNull()
      expect(spy).toHaveBeenCalled()
      spy.mockRestore()
    })

    it('handles localStorage errors gracefully', async () => {
      const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
      vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new Error('Storage full')
      })
      storage.saveSessionStats({ score: 1000, wordsFound: 5, tilesCleared: 20, duration: 120, longestWord: 'hello' })

      expect(spy).toHaveBeenCalled()
      spy.mockRestore()
    })
  })

  describe('getUserId', () => {
    it('creates new device ID when none exists', () => {
      const userId = storage.getUserId()
      
      expect(userId).toBeDefined()
      expect(userId.length).toBeGreaterThan(0)
      expect(localStorage.getItem('word_loom_device_id')).toBe(userId)
    })

    it('returns existing device ID', () => {
      localStorage.setItem('word_loom_device_id', 'existing-id-123')
      // Create a new storage instance to ensure clean state
      const newStorage = new StorageManager(mockSupabase)
      const userId = newStorage.getUserId()
      
      expect(userId).toBe('existing-id-123')
    })

    it('handles localStorage errors gracefully', () => {
      const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new Error('Storage error')
      })
      
      const userId = storage.getUserId()
      
      expect(userId).toContain('temp-')
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })
})
