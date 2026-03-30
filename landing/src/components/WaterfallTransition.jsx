import React from 'react'

// Letters that cascade like waterfall droplets
const WATERFALL_LETTERS = ['W', 'O', 'R', 'D', 'L', 'O', 'M']

export function WaterfallTransition({ isActive, theme }) {
  if (!isActive) return null

  return (
    <div className={`waterfall-transition active theme-${theme}`} aria-hidden="true">
      <div className="waterfall-container">
        {WATERFALL_LETTERS.map((letter) => (
          <span key={letter} className="waterfall-letter">
            {letter}
          </span>
        ))}
        <div className="waterfall-splash" />
      </div>
      <p className="waterfall-loading-text">Loading game...</p>
    </div>
  )
}