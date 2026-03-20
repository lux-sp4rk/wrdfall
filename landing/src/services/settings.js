import { getTheme, setTheme } from './theme.js'

const KEYS = {
  language: 'word-loom-language',
  difficulty: 'word-loom-difficulty',
}

export const DEFAULTS = {
  theme: 'light',
  language: 'en',
  difficulty: 'normal',
}

const VALID = {
  theme: ['light', 'dark'],
  language: ['en', 'es'],
  difficulty: ['normal', 'hard'],
}

/**
 * Sanitize setting value to prevent injection
 */
function sanitizeSettingValue(value, maxLength = 20) {
  if (!value || typeof value !== 'string') return ''
  return value
    .replace(/[<>"'&]/g, '') // Remove potential HTML/JS injection chars
    .trim()
    .slice(0, maxLength)
}

export function getSettings() {
  const result = { theme: getTheme() }
  for (const [key, storageKey] of Object.entries(KEYS)) {
    try {
      const saved = localStorage.getItem(storageKey)
      const sanitized = sanitizeSettingValue(saved)
      result[key] = VALID[key].includes(sanitized) ? sanitized : DEFAULTS[key]
    } catch (err) {
      // Fallback to default if localStorage fails
      console.warn(`Failed to read setting ${key}:`, err)
      result[key] = DEFAULTS[key]
    }
  }
  return result
}

export function saveSettings(partial) {
  if (!partial || typeof partial !== 'object') {
    console.warn('Invalid settings object provided')
    return false
  }
  
  let success = true
  
  if ('theme' in partial && VALID.theme.includes(partial.theme)) {
    setTheme(partial.theme)
  }
  
  for (const [key, value] of Object.entries(partial)) {
    if (key !== 'theme' && KEYS[key] && VALID[key]?.includes(value)) {
      const sanitized = sanitizeSettingValue(value)
      try {
        localStorage.setItem(KEYS[key], sanitized)
      } catch (err) {
        success = false
        console.warn(`Failed to save setting ${key}:`, err)
      }
    }
  }
  
  return success
}
