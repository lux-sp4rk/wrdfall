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

export function getSettings() {
  const result = { theme: getTheme() }
  for (const [key, storageKey] of Object.entries(KEYS)) {
    const saved = localStorage.getItem(storageKey)
    result[key] = VALID[key].includes(saved) ? saved : DEFAULTS[key]
  }
  return result
}

export function saveSettings(partial) {
  if ('theme' in partial && VALID.theme.includes(partial.theme)) {
    setTheme(partial.theme)
  }
  for (const [key, value] of Object.entries(partial)) {
    if (key !== 'theme' && KEYS[key] && VALID[key]?.includes(value)) {
      localStorage.setItem(KEYS[key], value)
    }
  }
}
