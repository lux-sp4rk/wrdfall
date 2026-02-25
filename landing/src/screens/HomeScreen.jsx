import React from 'react'

export function HomeScreen({ state, onPlayClick, onStatsClick, onSettingsClick }) {
  return (
    <div className={`landing-container theme-${state.theme}`}
         style={{ opacity: state.transitioning ? 0 : 1, transition: 'opacity 500ms ease-out' }}>
      <div className="landing-content">
        <div className="hero">
          <h1 className="logo">Word Loom</h1>
          <p className="tagline">Word-building meets Tetris</p>
        </div>

        {state.highScore !== null && (
          <div className="high-score-badge">
            <div className="badge-label">Your Best</div>
            <div className="badge-score">{state.highScore.toLocaleString()}</div>
          </div>
        )}

        {state.prefetchStatus === 'loading' && state.showProgress && (
          <div className="progress-container">
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${state.prefetchProgress}%` }} />
            </div>
            <div className="progress-text">Loading... {state.prefetchProgress}%</div>
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
          {state.transitioning ? 'Starting...' :
           (state.prefetchStatus === 'loading' && state.showProgress) ? 'Loading...' : 'Play'}
        </button>

        <div className="secondary-buttons">
          <button className="secondary-button" onClick={onStatsClick}>Stats</button>
          <button className="secondary-button" onClick={onSettingsClick}>Settings</button>
        </div>
      </div>
    </div>
  )
}
