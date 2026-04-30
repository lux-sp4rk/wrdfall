import React from 'react'
import { truncateText, sanitizeText } from '../services/hardening.js'

export function HomeScreen({ state, onPlayClick, onStatsClick, onSettingsClick, onRulesClick, onSignIn, onSignOut, isOnline = true }) {
  const { user, authLoading } = state;
  const displayError = state.error ? sanitizeText(truncateText(state.error, 150)) : null;
  const errorType = state.errorDetails?.type || 'unknown';
  const isRetryable = state.errorDetails?.retryable !== false;

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
          <h1 className="logo text-wrap">Wordfall</h1>
          <p className="tagline text-wrap">Word-building meets Tetris</p>
          {state.highScore > 0 && (
            <p className="high-score-text" role="status" aria-live="polite">
              Best: {state.highScore.toLocaleString()}
            </p>
          )}
        </div>

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
          className={`play-button ${state.prefetchStatus === 'loading' ? 'loading' : ''}`}
          onClick={onPlayClick}
          disabled={state.transitioning || state.prefetchStatus === 'error'}
          aria-label={state.transitioning ? 'Game starting' : (state.prefetchStatus === 'error' ? 'Game unavailable' : 'Play game')}
          aria-busy={state.transitioning}
        >
          {state.transitioning ? 'Starting…' :
           (state.prefetchStatus === 'loading') ? 'Loading…' : 'Play'}
        </button>

        {state.transitioning && (
          <p className="notification-cue" role="status" aria-live="polite">
            Go do what you need to — we'll ping you when it's ready.
          </p>
        )}

        <button type="button" className="rules-button" onClick={onRulesClick}>How to Play</button>

        <div className="card-divider" />

        <div className="secondary-buttons">
          <button type="button" className="secondary-button" onClick={onStatsClick}>Stats</button>
          <button type="button" className="secondary-button" onClick={onSettingsClick}>Settings</button>
        </div>

        <div className="card-divider" />

        {/* Auth section */}
        <div className="auth-section">
          {user ? (
            <div className="user-status">
              <span className="user-email">{user.email}</span>
              <button type="button" className="secondary-button sign-out-button" onClick={onSignOut} disabled={authLoading}>
                {authLoading ? 'Signing out…' : 'Sign out'}
              </button>
            </div>
          ) : isOnline ? (
            <button type="button" className="google-sign-in-button" onClick={onSignIn} disabled={authLoading}>
              {authLoading ? 'Connecting…' : 'Continue with Google'}
            </button>
          ) : null}
        </div>

        <p className="copyright">©2026 Lux Spark</p>
      </div>
    </div>
  )
}