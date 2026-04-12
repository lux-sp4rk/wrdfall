import { describe, it, expect, beforeEach } from 'vitest'
import { getSettings, saveSettings, DEFAULTS } from '../settings.js'

beforeEach(() => localStorage.clear())

describe('getSettings', () => {
  it('returns defaults when nothing is saved', () => {
    const s = getSettings()
    // theme is handled by theme.js which falls back to OS preference
    expect(['light', 'dark']).toContain(s.theme)
    expect(s.language).toBe('en')
    expect(s.difficulty).toBe('normal')
  })

  it('reads saved values', () => {
    localStorage.setItem('word-loom-theme', 'dark')
    localStorage.setItem('word-loom-language', 'es')
    localStorage.setItem('word-loom-difficulty', 'hard')
    const s = getSettings()
    expect(s.theme).toBe('dark')
    expect(s.language).toBe('es')
    expect(s.difficulty).toBe('hard')
  })

  it('ignores invalid values and returns default or OS preference', () => {
    localStorage.setItem('word-loom-theme', 'banana')
    const theme = getSettings().theme
    // Should be either light or dark (OS preference), not 'banana'
    expect(['light', 'dark']).toContain(theme)
  })
})

describe('saveSettings', () => {
  it('writes all three keys', () => {
    saveSettings({ theme: 'dark', language: 'es', difficulty: 'hard' })
    expect(localStorage.getItem('word-loom-theme')).toBe('dark')
    expect(localStorage.getItem('word-loom-language')).toBe('es')
    expect(localStorage.getItem('word-loom-difficulty')).toBe('hard')
  })

  it('partial update does not clobber other keys', () => {
    saveSettings({ theme: 'dark', language: 'en', difficulty: 'normal' })
    saveSettings({ theme: 'light' })
    expect(localStorage.getItem('word-loom-theme')).toBe('light')
    expect(localStorage.getItem('word-loom-language')).toBe('en')
  })

  it('returns false for invalid non-object input', () => {
    expect(saveSettings(null)).toBe(false)
    expect(saveSettings('string')).toBe(false)
    expect(saveSettings(123)).toBe(false)
  })

  it('returns false when localStorage throws', () => {
    const spy = vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => { throw new Error('quota exceeded') })
    const result = saveSettings({ language: 'es' })
    expect(result).toBe(false)
    spy.mockRestore()
  })

  it('falls back to defaults when localStorage.getItem throws', () => {
    const spy = vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => { throw new Error('disabled') })
    const s = getSettings()
    expect(s.language).toBe(DEFAULTS.language)
    expect(s.difficulty).toBe(DEFAULTS.difficulty)
    spy.mockRestore()
  })
})
