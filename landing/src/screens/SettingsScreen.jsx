import React from 'react'

export function SettingsScreen({ theme, onBack, onThemeChange }) {
  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="landing-content">
        <button onClick={onBack}>← Back</button>
        <p>Settings — coming in next task</p>
        {/* onThemeChange wired for Task 7 */}
      </div>
    </div>
  )
}
