import React, { useState, useEffect, useRef } from 'react'
import { createClient } from '@supabase/supabase-js'
import { StatsService } from '../services/statsService.js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_KEY
const supabase = supabaseUrl && !supabaseUrl.includes('placeholder')
  ? createClient(supabaseUrl, supabaseKey) : null

const statsService = new StatsService(supabase)

export function StatsScreen({ theme, onBack }) {
  const [stats, setStats] = useState(null)
  const [leaderboard, setLeaderboard] = useState([])
  const [copied, setCopied] = useState(false)
  const [showReset, setShowReset] = useState(false)
  const chartRef = useRef(null)

  useEffect(() => {
    statsService.getStats().then(setStats)
    statsService.getLeaderboard().then(setLeaderboard)
  }, [])

  useEffect(() => {
    if (stats?.session_history && chartRef.current) {
      drawChart(chartRef.current, stats.session_history, theme)
    }
  }, [stats, theme])

  function drawChart(canvas, history, currentTheme) {
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
  }

  function handleShare() {
    if (!stats) return
    navigator.clipboard.writeText(statsService.getShareText(stats))
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  async function handleReset() {
    await statsService.resetStats()
    setStats(await statsService.getStats())
    setShowReset(false)
  }

  if (!stats) {
    return (
      <div className={`landing-container theme-${theme}`}>
        <div className="main-card"><p className="tagline">Loading\u2026</p></div>
      </div>
    )
  }

  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="main-card stats-card">
        <div className="screen-header">
          <button className="back-button" onClick={onBack}>\u2190 Back</button>
          <h2 className="screen-title">Stats</h2>
          <div className="header-actions">
            <button className="icon-button" onClick={handleShare}>{copied ? '\u2713' : 'Share'}</button>
            <button className="icon-button icon-button-danger" onClick={() => setShowReset(true)}>Reset</button>
          </div>
        </div>

        <div className="stats-section">
          <h3 className="stats-section-title">Records</h3>
          <StatRow label="High Score" value={(stats.high_score ?? 0).toLocaleString()} />
          <StatRow label="Longest Word" value={stats.longest_word || '\u2014'} />
          <StatRow label="Max WPM" value={(stats.max_wpm ?? 0).toFixed(1)} />
        </div>

        <div className="card-divider" />

        <div className="stats-section">
          <h3 className="stats-section-title">Totals</h3>
          <StatRow label="Words Found" value={(stats.total_words ?? 0).toLocaleString()} />
          <StatRow label="Tiles Cleared" value={(stats.total_tiles ?? 0).toLocaleString()} />
          <StatRow label="Time Played" value={statsService.formatTime(stats.total_time ?? 0)} />
        </div>

        <div className="card-divider" />

        <div className="stats-section">
          <h3 className="stats-section-title">History</h3>
          {(stats.session_history?.length ?? 0) > 0
            ? <canvas ref={chartRef} className="history-chart" width={400} height={120} />
            : <p className="stats-empty">No games played yet</p>
          }
        </div>

        {leaderboard.length > 0 && (
          <>
            <div className="card-divider" />
            <div className="stats-section">
              <h3 className="stats-section-title">Leaderboard</h3>
              {leaderboard.map((entry, i) => (
                <div key={i} className="leaderboard-row">
                  <span className="lb-rank">{i + 1}.</span>
                  <span className="lb-name">{entry.profiles?.display_name ?? 'Anonymous'}</span>
                  <span className="lb-score">{(entry.score ?? 0).toLocaleString()}</span>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {showReset && (
        <div className="confirm-overlay">
          <div className="confirm-dialog">
            <p>Reset all stats? This cannot be undone.</p>
            <div className="confirm-actions">
              <button className="secondary-button" onClick={() => setShowReset(false)}>Cancel</button>
              <button className="play-button confirm-danger-button" onClick={handleReset}>Reset</button>
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
