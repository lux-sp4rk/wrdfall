import React, { useState } from 'react'
import { getSettings, saveSettings } from '../services/settings.js'

export function SettingsScreen({ theme, onBack, onThemeChange }) {
  const [settings, setSettings] = useState(() => getSettings())

  function handleChange(key, value) {
    const updated = { ...settings, [key]: value }
    setSettings(updated)
    saveSettings({ [key]: value })
    if (key === 'theme') onThemeChange(value)
  }

  const groups = [
    {
      key: 'theme',
      label: 'Theme',
      options: [{ value: 'light', label: 'Light' }, { value: 'dark', label: 'Dark' }],
    },
    {
      key: 'language',
      label: 'Language',
      options: [{ value: 'en', label: 'English' }, { value: 'es', label: 'Español' }],
    },
    {
      key: 'difficulty',
      label: 'Difficulty',
      options: [{ value: 'normal', label: 'Normal' }, { value: 'hard', label: 'Hard' }],
    },
  ]

  return (
    <div className={`landing-container theme-${settings.theme}`}>
      <div className="main-card">
        <div className="screen-header">
          <button className="back-button" onClick={onBack}>← Back</button>
          <h2 className="screen-title">Settings</h2>
        </div>

        {groups.map((group, i) => (
          <React.Fragment key={group.key}>
            {i > 0 && <div className="card-divider" />}
            <div className="settings-group">
              <span className="settings-label">{group.label}</span>
              <div className="radio-group">
                {group.options.map(opt => (
                  <label
                    key={opt.value}
                    className={`radio-option ${settings[group.key] === opt.value ? 'selected' : ''}`}
                  >
                    <input
                      type="radio"
                      name={group.key}
                      value={opt.value}
                      checked={settings[group.key] === opt.value}
                      onChange={() => handleChange(group.key, opt.value)}
                    />
                    {opt.label}
                  </label>
                ))}
              </div>
            </div>
          </React.Fragment>
        ))}
      </div>
    </div>
  )
}
