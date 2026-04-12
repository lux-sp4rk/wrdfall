import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import { StatsScreen } from '../StatsScreen.jsx'

let clipboardShouldFail = false

const { mockInstance } = vi.hoisted(() => {
  const instance = {
    getStats: vi.fn().mockResolvedValue({
      high_score: 12450,
      longest_word: 'QUARTZ',
      max_wpm: 8.4,
      total_words: 1240,
      total_tiles: 3892,
      total_time: 15120,
      session_history: [],
    }),
    getLeaderboard: vi.fn().mockResolvedValue([]),
    resetStats: vi.fn().mockResolvedValue(undefined),
    formatTime: vi.fn(s => `${Math.floor(s / 60)}m`),
    getShareText: vi.fn(() => 'Wordfall Stats'),
  }
  return { mockInstance: instance }
})

vi.mock('../../services/statsService.js', () => ({
  StatsService: vi.fn(function () { return mockInstance })
}))

vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn(() => null),
}))

const originalGetContext = global.HTMLCanvasElement.prototype.getContext

beforeEach(() => {
  vi.clearAllMocks()
  clipboardShouldFail = false
  // Reset mocks to default values
  mockInstance.getStats.mockResolvedValue({
    high_score: 12450,
    longest_word: 'QUARTZ',
    max_wpm: 8.4,
    total_words: 1240,
    total_tiles: 3892,
    total_time: 15120,
    session_history: [],
  })
  mockInstance.getLeaderboard.mockResolvedValue([])
  mockInstance.resetStats.mockResolvedValue(undefined)
  mockInstance.formatTime.mockImplementation(s => `${Math.floor(s / 60)}m`)
  mockInstance.getShareText.mockReturnValue('Wordfall Stats')

  global.navigator.clipboard = {
    writeText: vi.fn(() =>
      clipboardShouldFail
        ? Promise.reject(new Error('Clipboard unavailable'))
        : Promise.resolve()
    ),
  }

  global.HTMLCanvasElement.prototype.getContext = vi.fn(() => ({
    clearRect: vi.fn(),
    fillStyle: '',
    beginPath: vi.fn(),
    roundRect: vi.fn(),
    rect: vi.fn(),
    fill: vi.fn(),
  }))
})

afterEach(() => {
  delete global.navigator.clipboard
  global.HTMLCanvasElement.prototype.getContext = originalGetContext
})

describe('StatsScreen', () => {
  it('shows loading state initially', async () => {
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    const skeletonElements = document.querySelectorAll('.skeleton')
    expect(skeletonElements.length).toBeGreaterThan(0)
  })

  it('renders records section after stats load', async () => {
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Records'))
    expect(screen.getByText('12,450')).toBeTruthy()
    expect(screen.getByText('QUARTZ')).toBeTruthy()
    expect(screen.getByText('8.4')).toBeTruthy()
  })

  it('renders totals section after stats load', async () => {
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Totals'))
    expect(screen.getByText('1,240')).toBeTruthy()
    expect(screen.getByText('3,892')).toBeTruthy()
  })

  it('shows "No games played yet" when session_history is empty', async () => {
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('No games played yet'))
  })

  it('shows confirm dialog when Reset is clicked, hides on Cancel', async () => {
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Reset'))
    fireEvent.click(screen.getByText('Reset'))
    expect(screen.getByText('Reset all stats? This cannot be undone.')).toBeTruthy()
    fireEvent.click(screen.getByText('Cancel'))
    expect(screen.queryByText('Reset all stats? This cannot be undone.')).toBeNull()
  })

  it('calls onBack when Back button is clicked', async () => {
    const onBack = vi.fn()
    render(<StatsScreen theme="light" onBack={onBack} />)
    await waitFor(() => screen.getByText('← Back'))
    fireEvent.click(screen.getByText('← Back'))
    expect(onBack).toHaveBeenCalledOnce()
  })

  it('shows empty state when all stats are zero', async () => {
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 0, longest_word: '', max_wpm: 0,
      total_words: 0, total_tiles: 0, total_time: 0,
      session_history: [],
    })
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('No Stats Yet'))
    expect(screen.getByText('Play a game to see your statistics here!')).toBeTruthy()
  })

  it('shows leaderboard entries when data is available', async () => {
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 5000, longest_word: 'HELLO', max_wpm: 7.0,
      total_words: 100, total_tiles: 300, total_time: 3600,
      session_history: [],
    })
    mockInstance.getLeaderboard.mockResolvedValueOnce([
      { user_id: 'u1', score: 5000, rank: 1, profiles: { display_name: 'Alice' } },
      { user_id: 'u2', score: 3000, rank: 2, profiles: { display_name: 'Bob' } },
    ])
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Leaderboard'))
    expect(screen.getByText('Alice')).toBeTruthy()
    expect(screen.getByText('Bob')).toBeTruthy()
  })

  it('shows leaderboard empty state when no entries', async () => {
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 100, longest_word: '', max_wpm: 5.0,
      total_words: 10, total_tiles: 30, total_time: 60,
      session_history: [],
    })
    mockInstance.getLeaderboard.mockResolvedValueOnce([])
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Leaderboard'))
    expect(screen.getByText('No leaderboard data available')).toBeTruthy()
  })

  it('copies stats to clipboard when Share is clicked', async () => {
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 1000, longest_word: '', max_wpm: 5.0,
      total_words: 10, total_tiles: 30, total_time: 60,
      session_history: [],
    })
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Share'))
    await act(async () => { fireEvent.click(screen.getByText('Share')) })
    await waitFor(() => expect(navigator.clipboard.writeText).toHaveBeenCalled())
  })

  it('handles clipboard failure gracefully', async () => {
    clipboardShouldFail = true
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 1000, longest_word: '', max_wpm: 5.0,
      total_words: 10, total_tiles: 30, total_time: 60,
      session_history: [],
    })
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Share'))
    // Should not throw
    await act(async () => { fireEvent.click(screen.getByText('Share')) })
  })

  it('resets stats when Reset is confirmed', async () => {
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 500, longest_word: '', max_wpm: 0,
      total_words: 5, total_tiles: 15, total_time: 30,
      session_history: [],
    })
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('Reset'))
    fireEvent.click(screen.getByText('Reset'))
    await waitFor(() => screen.getByText('Reset all stats? This cannot be undone.'))
    const confirmReset = document.querySelector('.confirm-danger-button')
    await act(async () => { fireEvent.click(confirmReset) })
    await waitFor(() => expect(mockInstance.resetStats).toHaveBeenCalledOnce())
  })

  it('shows error state when getStats throws', async () => {
    mockInstance.getStats.mockRejectedValueOnce(new Error('Load failed'))
    render(<StatsScreen theme="light" onBack={vi.fn()} isOnline={true} />)
    await waitFor(() => screen.getByText('Failed to Load'))
    expect(screen.getByText('Failed to load statistics. Please try again.')).toBeTruthy()
  })

  it('shows retry button in error state that reloads stats', async () => {
    mockInstance.getStats
      .mockRejectedValueOnce(new Error('Load failed'))
      .mockResolvedValueOnce({
        high_score: 0, longest_word: '', max_wpm: 0,
        total_words: 0, total_tiles: 0, total_time: 0,
        session_history: [],
      })
    render(<StatsScreen theme="light" onBack={vi.fn()} isOnline={true} />)
    await waitFor(() => screen.getByText('Failed to Load'))
    await act(async () => { fireEvent.click(screen.getByText('Try Again')) })
    await waitFor(() => screen.getByText('No Stats Yet'))
  })

  it('disables retry button when offline', async () => {
    mockInstance.getStats.mockRejectedValueOnce(new Error('Load failed'))
    render(<StatsScreen theme="light" onBack={vi.fn()} isOnline={false} />)
    await waitFor(() => screen.getByText('Failed to Load'))
    expect(screen.queryByText('Offline')).toBeTruthy()
  })

  it('renders canvas chart when session_history has entries', async () => {
    mockInstance.getStats.mockResolvedValueOnce({
      high_score: 1000,
      longest_word: 'TEST',
      max_wpm: 6.0,
      total_words: 50,
      total_tiles: 150,
      total_time: 600,
      session_history: [
        { score: 500, wpm: 5.0, words_found: 5, duration: 60, timestamp: '2024-01-01' },
        { score: 1000, wpm: 6.0, words_found: 10, duration: 120, timestamp: '2024-01-02' },
      ],
    })
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    await waitFor(() => screen.getByText('History'))
    expect(document.querySelector('canvas.history-chart')).toBeTruthy()
  })
})
