import React from 'react'

export function StatsScreen({ theme, onBack }) {
  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="landing-content">
        <button onClick={onBack}>← Back</button>
        <p>Stats — coming in next task</p>
      </div>
    </div>
  )
}
