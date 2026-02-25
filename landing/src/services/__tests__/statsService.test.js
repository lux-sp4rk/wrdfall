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
