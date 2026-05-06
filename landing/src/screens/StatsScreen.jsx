import React, { useState, useEffect, useRef, useCallback } from 'react'
import { createClient } from '@supabase/supabase-js'
import { StatsService } from '../services/statsService.js'
import { formatDuration, sanitizeText, truncateText, formatNumber } from '../services/hardening.js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_KEY
const supabase = supabaseUrl && !supabaseUrl.includes('placeholder')
  ? createClient(supabaseUrl, supabaseKey) : null

const statsService = new StatsService(supabase)

export function StatsScreen({ theme, onBack, language = 'en', isOnline = true, user, supabase, onSignIn }) {
  const [stats, setStats] = useState(null)
  const [leaderboard, setLeaderboard] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [copied, setCopied] = useState(false)
  const [showReset, setShowReset] = useState(false)
  const [authLoading, setAuthLoading] = useState(false)
  const chartRef = useRef(null)

  // Load stats with error handling
  const loadStats = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [statsData, leaderboardData] = await Promise.all([
        statsService.getStats(user?.id),
        statsService.getLeaderboard(20)
      ])
      setStats(statsData)
      setLeaderboard(leaderboardData || [])
    } catch (err) {
      console.error('Failed to load stats:', err)
      setError('Failed to load statistics. Please try again.')
    } finally {
      setLoading(false)
    }
  }, [user?.id])

  useEffect(() => {
    loadStats()
  }, [loadStats])

  const drawChart = useCallback((canvas, history, currentTheme) => {
    const ctx = canvas.getContext('2d')
    const { width, height } = canvas
    ctx.clearRect(0, 0, width, height)
    const recent = history.slice(-10)
    if (!recent.length) return
    const maxScore = Math.max(...recent.map(s => s.score), 1)
    const barW = (width / recent.length) * 0.7
    const gap = (width / recent.length) * 0.3
    const accentHex = currentTheme === 'dark' ? '#F29170' : '#E07857'
    recent.forEach((s, i) => {
      const barH = (s.score / maxScore) * (height - 24)
      const x = i * (barW + gap) + gap / 2
      const y = height - barH - 20
      const alpha = Math.round((0.4 + (i / recent.length) * 0.6) * 255).toString(16).padStart(2, '0')
      ctx.fillStyle = accentHex + alpha
      ctx.beginPath()
      ctx.roundRect?.(x, y, barW, barH, 4) ?? ctx.rect(x, y, barW, barH)
      ctx.fill()
    })
  }, [])

  useEffect(() => {
    if (stats?.session_history && chartRef.current) {
      drawChart(chartRef.current, stats.session_history, theme)
    }
  }, [stats, theme, drawChart])

  async function handleShare() {
    if (!stats) return
    try {
      await navigator.clipboard.writeText(statsService.getShareText(stats))
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    } catch {
      // Clipboard API unavailable (non-HTTPS or restricted context) — no-op
    }
  }

  async function handleReset() {
    await statsService.resetStats()
    await loadStats()
    setShowReset(false)
  }

  // Loading skeleton state
  if (loading) {
    return (
      <div className={`landing-container theme-${theme}`}>
        <div className="main-card stats-card">
          <div className="screen-header">
            <button type="button" className="back-button" onClick={onBack}>← Back</button>
            <h2 className="screen-title">Stats</h2>
            <div className="header-actions skeleton skeleton-stat" style={{ width: '100px' }} />
          </div>
          
          <div className="stats-section">
            <h3 className="stats-section-title">Records</h3>
            {[1, 2, 3].map(i => (
              <div key={i} className="stat-row">
                <div className="skeleton skeleton-text" style={{ width: '100px' }} />
                <div className="skeleton skeleton-stat" />
              </div>
            ))}
          </div>
          
          <div className="card-divider" />
          
          <div className="stats-section">
            <h3 className="stats-section-title">History</h3>
            <div className="skeleton" style={{ height: '120px', width: '100%' }} />
          </div>
        </div>
      </div>
    )
  }

  // Error state
  if (error) {
    return (
      <div className={`landing-container theme-${theme}`}>
        <div className="main-card stats-card">
          <div className="screen-header">
            <button type="button" className="back-button" onClick={onBack}>← Back</button>
            <h2 className="screen-title">Stats</h2>
          </div>
          
          <div className="empty-state">
            <div className="error-icon" aria-hidden="true">⚠️</div>
            <h3 className="empty-state-title">Failed to Load</h3>
            <p className="empty-state-message">{error}</p>
            <button 
              type="button"
              className="retry-button" 
              onClick={loadStats}
              disabled={!isOnline}
            >
              {isOnline ? 'Try Again' : 'Offline'}
            </button>
          </div>
        </div>
      </div>
    )
  }

  // Check if user has any stats
  const hasStats = stats && (
    stats.high_score > 0 || 
    stats.total_words > 0 || 
    stats.total_tiles > 0 ||
    (stats.session_history?.length ?? 0) > 0
  )

  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="main-card stats-card">
        <div className="screen-header">
          <button type="button" className="back-button" onClick={onBack}>← Back</button>
          <h2 className="screen-title">Stats</h2>
          <div className="header-actions">
            {hasStats && (
              <button type="button" className="icon-button" onClick={handleShare} disabled={!stats}>
                {copied ? '✓' : 'Share'}
              </button>
            )}
            <button type="button" className="icon-button icon-button-danger" onClick={() => setShowReset(true)}>Reset</button>
          </div>
        </div>

        {!hasStats ? (
          <div className="empty-state">
            <div className="empty-state-icon" aria-hidden="true">📊</div>
            <h3 className="empty-state-title">No Stats Yet</h3>
            <p className="empty-state-message">
              Play a game to see your statistics here!
            </p>
            {!user && (
              <>
                <div className="card-divider" style={{ margin: '16px 0' }} />
                <p className="empty-state-message" style={{ fontSize: '0.9em', opacity: 0.8 }}>
                  Sign in to save your scores to the leaderboard
                </p>
                <button
                  type="button"
                  className="google-sign-in-button"
                  onClick={onSignIn}
                  disabled={!isOnline || authLoading}
                  style={{ marginTop: '12px' }}
                >
                  {authLoading ? 'Connecting…' : isOnline ? 'Continue with Google' : 'Offline'}
                </button>
              </>
            )}
          </div>
        ) : (
          <>
            <div className="stats-section">
              <h3 className="stats-section-title">Records</h3>
              <StatRow label="High Score" value={formatNumber(stats.high_score ?? 0, language)} />
              <StatRow 
                label="Longest Word" 
                value={stats.longest_word ? truncateText(sanitizeText(stats.longest_word), 15) : '—'} 
              />
              <StatRow label="Max WPM" value={(stats.max_wpm ?? 0).toFixed(1)} />
            </div>

            <div className="card-divider" />

            <div className="stats-section">
              <h3 className="stats-section-title">Totals</h3>
              <StatRow label="Words Found" value={formatNumber(stats.total_words ?? 0, language)} />
              <StatRow label="Tiles Cleared" value={formatNumber(stats.total_tiles ?? 0, language)} />
              <StatRow label="Time Played" value={formatDuration(stats.total_time ?? 0, language)} />
            </div>

            <div className="card-divider" />

            <div className="stats-section">
              <h3 className="stats-section-title">History</h3>
              {(stats.session_history?.length ?? 0) > 0 ? (
                <canvas ref={chartRef} className="history-chart" width={400} height={120} />
              ) : (
                <div className="empty-state" style={{ padding: '20px' }}>
                  <p className="stats-empty">No games played yet</p>
                </div>
              )}
            </div>

            {leaderboard.length > 0 ? (
              <>
                <div className="card-divider" />
                <div className="stats-section">
                  <h3 className="stats-section-title">Leaderboard</h3>
                  {leaderboard.map((entry) => (
                    <div 
                      key={entry.user_id || `${entry.score}-${Math.random()}`} 
                      className="leaderboard-row"
                    >
                      <span className="lb-rank">{entry.rank || 0}.</span>
                      <span 
                        className="lb-name" 
                        title={sanitizeText(entry.profiles?.display_name ?? 'Anonymous')}
                      >
                        {truncateText(sanitizeText(entry.profiles?.display_name ?? 'Anonymous'), 20)}
                      </span>
                      <span className="lb-score">{formatNumber(entry.score ?? 0, language)}</span>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <>
                <div className="card-divider" />
                <div className="stats-section">
                  <h3 className="stats-section-title">Leaderboard</h3>
                  <div className="empty-state" style={{ padding: '20px' }}>
                    <p className="stats-empty">No leaderboard data available</p>
                  </div>
                </div>
              </>
            )}
          </>
        )}
      </div>

      {showReset && (
        <div className="confirm-overlay" role="dialog" aria-modal="true" aria-labelledby="reset-title">
          <div className="confirm-dialog">
            <p id="reset-title">Reset all stats? This cannot be undone.</p>
            <div className="confirm-actions">
              <button type="button" className="secondary-button" onClick={() => setShowReset(false)}>Cancel</button>
              <button type="button" className="play-button confirm-danger-button" onClick={handleReset}>Reset</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function StatRow({ label, value }) {
  return (
    <div className="stat-row">
      <span className="stat-label">{label}</span>
      <span className="stat-value">{value}</span>
    </div>
  )
}
