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

  it('falls back to localStorage when supabase fetch throws', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 999 }))
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockRejectedValue(new Error('Network error')),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const stats = await s.getStats('user-123')
    // Falls back to localStorage
    expect(stats.high_score).toBe(999)
  })

  it('returns local stats when no supabase client and userId provided', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 500 }))
    const s = new StatsService(null)
    const stats = await s.getStats('user-123')
    expect(stats.high_score).toBe(500)
  })

  it('returns merged profile + sessions from supabase when userId provided', async () => {
    const mockProfile = { high_score: 2000, longest_word: 'XYLEMU', max_wpm: 9.1, total_words: 300, total_tiles: 900, total_time: 3600 }
    const mockSessions = [{ score: 2000, wpm: 9.1, words_found: 30, duration: 120, timestamp: '2024-01-01' }]
    const s = new StatsService({})
    vi.spyOn(s, '_fetchProfile').mockResolvedValue(mockProfile)
    vi.spyOn(s, '_fetchSessions').mockResolvedValue(mockSessions)
    const stats = await s.getStats('user-123')
    expect(stats.high_score).toBe(2000)
    expect(stats.session_history).toHaveLength(1)
  })
})

describe('StatsService._fetchProfile', () => {
  it('returns profile data on success', async () => {
    const mockProfile = { high_score: 5000, longest_word: 'OXYGEN', max_wpm: 7.2, total_words: 500, total_tiles: 1500, total_time: 7200 }
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: mockProfile, error: null }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const profile = await s._fetchProfile('user-abc')
    expect(profile).toEqual(mockProfile)
  })

  it('throws when profile fetch returns error', async () => {
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            single: vi.fn().mockResolvedValue({ data: null, error: { message: 'Not found' } }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    await expect(s._fetchProfile('bad-user')).rejects.toThrow()
  })
})

describe('StatsService._fetchSessions', () => {
  it('returns sessions on success', async () => {
    const mockSessions = [{ score: 100, wpm: 4.0, words_found: 10, duration: 60, timestamp: '2024-01-01' }]
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            order: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue({ data: mockSessions, error: null }),
            }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const sessions = await s._fetchSessions('user-xyz')
    expect(sessions).toHaveLength(1)
  })

  it('returns empty array on error', async () => {
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          eq: vi.fn().mockReturnValue({
            order: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue({ data: null, error: { message: 'Query failed' } }),
            }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const sessions = await s._fetchSessions('bad-user')
    expect(sessions).toEqual([])
  })
})

describe('StatsService.getLeaderboard', () => {
  it('returns empty array when no supabase client', async () => {
    const s = new StatsService(null)
    const result = await s.getLeaderboard()
    expect(result).toEqual([])
  })

  it('returns ranked leaderboard entries on success', async () => {
    const mockData = [
      { user_id: 'u1', score: 1000, profiles: { display_name: 'Alice' } },
      { user_id: 'u2', score: 800, profiles: { display_name: 'Bob' } },
    ]
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue({ data: mockData, error: null }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const result = await s.getLeaderboard(10)
    expect(result).toHaveLength(2)
    expect(result[0].rank).toBe(1)
    expect(result[1].rank).toBe(2)
    expect(result[0].profiles.display_name).toBe('Alice')
  })

  it('returns empty array on leaderboard error', async () => {
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue({ data: null, error: { message: 'Table not found' } }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const result = await s.getLeaderboard()
    expect(result).toEqual([])
  })

  it('maps rank onto each entry', async () => {
    const mockData = [
      { user_id: 'u1', score: 500, profiles: { display_name: 'C' } },
      { user_id: 'u2', score: 300, profiles: { display_name: 'D' } },
      { user_id: 'u3', score: 100, profiles: { display_name: 'E' } },
    ]
    const mockSupabase = {
      from: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue({ data: mockData, error: null }),
          }),
        }),
      }),
    }
    const s = new StatsService(mockSupabase)
    const result = await s.getLeaderboard(3)
    expect(result[0].rank).toBe(1)
    expect(result[1].rank).toBe(2)
    expect(result[2].rank).toBe(3)
  })
})

describe('StatsService.resetStats', () => {
  it('removes stats from localStorage', async () => {
    localStorage.setItem('word-loom-stats', JSON.stringify({ high_score: 999 }))
    const s = new StatsService(null)
    await s.resetStats()
    expect(localStorage.getItem('word-loom-stats')).toBeNull()
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

  it('shows em dash when longest word is empty', () => {
    const s = new StatsService(null)
    const text = s.getShareText({
      high_score: 100,
      longest_word: '',
      max_wpm: 0,
      total_words: 0,
      total_tiles: 0,
      total_time: 0,
    })
    expect(text).toContain('Longest Word: —')
  })
})
