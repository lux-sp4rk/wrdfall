import React from 'react'
import { truncateText, sanitizeText } from '../services/hardening.js'

export function HomeScreen({ state, onPlayClick, onStatsClick, onSettingsClick, onRulesClick, isOnline = true }) {
  // Sanitize and truncate error messages to prevent UI breakage
  const displayError = state.error ? sanitizeText(truncateText(state.error, 150)) : null
  const errorType = state.errorDetails?.type || 'unknown'
  const isRetryable = state.errorDetails?.retryable !== false

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
          <h1 className="logo text-wrap">Word Loom</h1>
          <p className="tagline text-wrap">Word-building meets Tetris</p>
          {state.highScore > 0 && (
            <p className="high-score-text" role="status" aria-live="polite">
              Best: {state.highScore.toLocaleString()}
            </p>
          )}
        </div>

        {state.prefetchStatus === 'loading' && state.showProgress && (
          <div className="progress-container" role="progressbar" aria-valuenow={state.prefetchProgress} aria-valuemin={0} aria-valuemax={100}>
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${state.prefetchProgress}%` }} />
            </div>
            <div className="progress-text">Loading… {state.prefetchProgress}%</div>
          </div>
        )}

        {displayError && (
          <div className="error-container-enhanced" role="alert" aria-live="polite">
            <div className="error-icon" aria-hidden="true">⚠️</div>
            <h3 className="error-title">
              {errorType === 'network' ? 'Connection Error' :
               errorType === 'timeout' ? 'Request Timeout' :
               errorType === 'not-found' ? 'Not Found' :
               errorType === 'server' ? 'Server Error' :
               'Something Went Wrong'}
            </h3>
            <p className="error-details">{displayError}</p>
            <div className="error-actions">
              {isRetryable && state.prefetchStatus === 'error' && (
                <button 
                  type="button"
                  className="retry-button" 
                  onClick={state.onRetry}
                  disabled={!isOnline}
                  aria-label="Retry loading game"
                >
                  {isOnline ? 'Try Again' : 'Offline'}
                </button>
              )}
              {!isOnline && (
                <span className="error-details">Check your internet connection and try again.</span>
              )}
            </div>
          </div>
        )}

        <button 
          type="button"
          className="play-button" 
          onClick={onPlayClick} 
          disabled={state.transitioning || state.prefetchStatus === 'error'}
          aria-label={state.transitioning ? 'Game starting' : (state.prefetchStatus === 'error' ? 'Game unavailable' : 'Play game')}
          aria-busy={state.transitioning}
        >
          {state.transitioning ? 'Starting…' :
           (state.prefetchStatus === 'loading' && state.showProgress) ? 'Loading…' : 'Play'}
        </button>

        <button type="button" className="rules-button" onClick={onRulesClick}>How to Play</button>

        <div className="secondary-buttons">
          <button type="button" className="secondary-button" onClick={onStatsClick}>Stats</button>
          <button type="button" className="secondary-button" onClick={onSettingsClick}>Settings</button>
        </div>

        <div className="card-divider" />
        <p className="copyright">©2026 Lux Spark</p>
      </div>
    </div>
  )
}
