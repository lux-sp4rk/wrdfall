import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { theme, setTheme, getTheme, detectSystemTheme } from '../theme.js'

describe('Theme Module', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.classList.remove('dark')
  })

  afterEach(() => {
    localStorage.clear()
    document.documentElement.classList.remove('dark')
    vi.restoreAllMocks()
  })

  describe('getTheme', () => {
    it('returns saved theme from localStorage', () => {
      localStorage.setItem('word-loom-theme', 'dark')
      expect(getTheme()).toBe('dark')
    })

    it('detects system preference on first visit', () => {
      // Mock matchMedia for light mode
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query === '(prefers-color-scheme: light)',
          media: query,
        })),
      })
      
      expect(getTheme()).toBe('light')
    })

    it('defaults to dark when system preference unavailable', () => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: undefined,
      })
      
      expect(getTheme()).toBe('dark')
    })

    it('handles localStorage errors gracefully', () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new Error('Storage access denied')
      })
      
      expect(getTheme()).toBe('dark')
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })

  describe('setTheme', () => {
    it('sets light theme correctly', () => {
      setTheme('light')
      expect(localStorage.getItem('word-loom-theme')).toBe('light')
    })

    it('sets dark theme correctly', () => {
      setTheme('dark')
      expect(localStorage.getItem('word-loom-theme')).toBe('dark')
    })

    it('defaults to dark for invalid theme values', () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      setTheme('invalid')
      expect(localStorage.getItem('word-loom-theme')).toBe('dark')
      expect(spy).toHaveBeenCalledWith('Invalid theme: invalid, defaulting to dark')
      spy.mockRestore()
    })

    it('handles localStorage errors gracefully', () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new Error('Storage full')
      })
      
      setTheme('dark')
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })

  describe('detectSystemTheme', () => {
    it('returns light when system prefers light mode', () => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query === '(prefers-color-scheme: light)',
          media: query,
        })),
      })
      
      expect(detectSystemTheme()).toBe('light')
    })

    it('returns dark when system prefers dark mode', () => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: false,
          media: query,
        })),
      })
      
      expect(detectSystemTheme()).toBe('dark')
    })

    it('returns dark when matchMedia is unavailable', () => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: undefined,
      })
      
      expect(detectSystemTheme()).toBe('dark')
    })

    it('handles matchMedia errors gracefully', () => {
      const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(() => {
          throw new Error('matchMedia error')
        }),
      })
      
      expect(detectSystemTheme()).toBe('dark')
      expect(spy).toHaveBeenCalled()
      
      spy.mockRestore()
    })
  })
})
