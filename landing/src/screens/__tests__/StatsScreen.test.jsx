import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { StatsScreen } from '../StatsScreen.jsx'

// vi.mock is hoisted, so the mock object must be defined inside the factory.
// StatsScreen calls `new StatsService()` at module scope, so we need a real
// constructor function (arrow functions cannot be used with `new`).
vi.mock('../../services/statsService.js', () => {
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
    getShareText: vi.fn(() => 'Word Loom Stats'),
  }
  return { StatsService: vi.fn(function () { return instance }) }
})

// Mock @supabase/supabase-js to avoid real client construction
vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn(() => null),
}))

beforeEach(() => {
  vi.clearAllMocks()
})

describe('StatsScreen', () => {
  it('shows loading state initially', async () => {
    render(<StatsScreen theme="light" onBack={vi.fn()} />)
    // Should show skeleton loading elements
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
})
