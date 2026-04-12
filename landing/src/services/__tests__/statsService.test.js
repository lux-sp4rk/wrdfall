import { describe, it, expect, beforeEach, vi } from 'vitest'
import { StatsService, EMPTY_STATS } from '../statsService.js'

beforeEach(() => {
  localStorage.clear()
  vi.clearAllMocks()
})

describe('StatsService.getStats', () => {
  it('returns empty stats when nothing saved', async () => {
    const s = new StatsService(null)
    const stats = await s.getStats()
    expect(stats.high_score).toBe(0)
    expect(stats.total_words).toBe(0)
    expect(stats.session_history).toEqual([])
  })

  it('reads guest stats from localStorage', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({
      high_score: 1234,
      longest_word: 'QUARTZ',
      total_words: 42,
      session_history: [{ score: 1234, wpm: 5.2 }],
    }))
    const s = new StatsService(null)
    const stats = await s.getStats()
    expect(stats.high_score).toBe(1234)
    expect(stats.longest_word).toBe('QUARTZ')
    expect(stats.session_history).toHaveLength(1)
  })

  it('merges EMPTY_STATS defaults for missing keys', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 500 }))
    const s = new StatsService(null)
    const stats = await s.getStats()
    expect(stats.high_score).toBe(500)
    expect(stats.total_tiles).toBe(0)
  })
})

describe('StatsService.formatTime', () => {
  const s = new StatsService(null)
  it('formats hours and minutes', () => expect(s.formatTime(3661)).toBe('1h 1m'))
  it('formats minutes only', () => expect(s.formatTime(90)).toBe('1m'))
  it('shows <1m for short durations', () => expect(s.formatTime(30)).toBe('<1m'))
})

describe('StatsService.getShareText', () => {
  it('formats stats as copyable text', () => {
    const s = new StatsService(null)
    const text = s.getShareText({
      high_score: 1000,
      longest_word: 'QUARTZ',
      max_wpm: 6.5,
      total_words: 42,
      total_tiles: 100,
      total_time: 90,
    })
    expect(text).toContain('High Score: 1000')
    expect(text).toContain('Longest Word: QUARTZ')
  })
})

describe('StatsService.getLeaderboard', () => {
  it('returns empty array when supabase is null', async () => {
    const s = new StatsService(null)
    const board = await s.getLeaderboard()
    expect(board).toEqual([])
  })

  it('returns ranked leaderboard on success', async () => {
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          order: vi.fn(() => ({
            limit: vi.fn().mockResolvedValue({
              data: [
                { user_id: 'u1', score: 5000, profiles: { display_name: 'Alice' } },
                { user_id: 'u2', score: 3000, profiles: { display_name: 'Bob' } },
              ],
              error: null,
            })
          }))
        }))
      }))
    }
    const s = new StatsService(mockSupabase)
    const board = await s.getLeaderboard(10)
    expect(board).toHaveLength(2)
    expect(board[0].rank).toBe(1)
    expect(board[1].rank).toBe(2)
  })

  it('returns empty array on supabase error', async () => {
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          order: vi.fn(() => ({
            limit: vi.fn().mockResolvedValue({
              data: null,
              error: new Error('network'),
            })
          }))
        }))
      }))
    }
    const s = new StatsService(mockSupabase)
    const board = await s.getLeaderboard()
    expect(board).toEqual([])
  })
})

describe('StatsService.resetStats', () => {
  it('removes localStorage key', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 999 }))
    const s = new StatsService(null)
    await s.resetStats()
    expect(localStorage.getItem('word-loom-stats')).toBeNull()
  })
})

describe('StatsService._getLocalStats', () => {
  it('returns EMPTY_STATS for invalid JSON', () => {
    localStorage.setItem('word-loom-stats', 'not-json')
    const s = new StatsService(null)
    const stats = s._getLocalStats()
    expect(stats.high_score).toBe(0)
    expect(stats.session_history).toEqual([])
  })
})

describe('StatsService.getStats with supabase', () => {
  it('fetches from supabase when userId is provided', async () => {
    const mockSupabase = {
      from: vi.fn((table) => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            single: vi.fn().mockResolvedValue({
              data: { high_score: 9999 },
              error: null,
            }),
            order: vi.fn(() => ({
              limit: vi.fn().mockResolvedValue({ data: [], error: null })
            }))
          }))
        }))
      }))
    }
    const s = new StatsService(mockSupabase)
    const stats = await s.getStats('user-123')
    expect(stats.high_score).toBe(9999)
    expect(stats.session_history).toEqual([])
  })

  it('falls back to localStats on supabase error', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 555 }))
    const mockSupabase = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          eq: vi.fn(() => ({
            single: vi.fn().mockRejectedValue(new Error('network')),
          }))
        }))
      }))
    }
    const s = new StatsService(mockSupabase)
    const stats = await s.getStats('user-123')
    expect(stats.high_score).toBe(555)
  })
})
