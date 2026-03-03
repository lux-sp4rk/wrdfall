import React from 'react'

export function HomeScreen({ state, onPlayClick, onStatsClick, onSettingsClick, onRulesClick }) {
  return (
    <div className={`landing-container theme-${state.theme}`}
         style={{ opacity: state.transitioning ? 0 : 1, transition: 'opacity 500ms ease-out' }}>

      {/* Decorative tiles — matches Godot's DecorativePattern */}
      <div className="decorative-pattern" aria-hidden="true">
        <div className="letter-tile tile-1" />
        <div className="letter-tile tile-2" />
        <div className="letter-tile tile-3" />
        <div className="letter-tile tile-4" />
      </div>

      {/* Main card */}
      <div className="main-card">
        <div className="title-section">
          <h1 className="logo">Word Loom</h1>
          <p className="tagline">Word-building meets Tetris</p>
          {state.highScore > 0 && (
            <p className="high-score-text">Best: {state.highScore.toLocaleString()}</p>
          )}
        </div>

        {state.prefetchStatus === 'loading' && state.showProgress && (
          <div className="progress-container">
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${state.prefetchProgress}%` }} />
            </div>
            <div className="progress-text">Loading… {state.prefetchProgress}%</div>
          </div>
        )}

        {state.error && (
          <div className="error-container">
            <div className="error-message">{state.error}</div>
            {state.prefetchStatus === 'error' && (
              <button className="retry-button" onClick={state.onRetry}>Retry</button>
            )}
          </div>
        )}

        <button className="play-button" onClick={onPlayClick} disabled={state.transitioning || state.prefetchStatus === 'error'}>
          {state.transitioning ? 'Starting…' :
           (state.prefetchStatus === 'loading' && state.showProgress) ? 'Loading…' : 'Play'}
        </button>

        <button className="rules-button" onClick={onRulesClick}>How to Play</button>

        <div className="secondary-buttons">
          <button className="secondary-button" onClick={onStatsClick}>Stats</button>
          <button className="secondary-button" onClick={onSettingsClick}>Settings</button>
        </div>

        <div className="card-divider" />
        <p className="copyright">©2026 Lux Spark</p>
      </div>
    </div>
  )
}
