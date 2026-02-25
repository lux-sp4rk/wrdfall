const KEYS = {
  theme: 'word-loom-theme',
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
  const result = {}
  for (const [key, storageKey] of Object.entries(KEYS)) {
    const saved = localStorage.getItem(storageKey)
    result[key] = VALID[key].includes(saved) ? saved : DEFAULTS[key]
  }
  return result
}

export function saveSettings(partial) {
  for (const [key, value] of Object.entries(partial)) {
    if (KEYS[key] && VALID[key]?.includes(value)) {
      localStorage.setItem(KEYS[key], value)
    }
  }
}
