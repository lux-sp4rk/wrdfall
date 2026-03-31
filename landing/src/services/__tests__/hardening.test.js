import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  sanitizeText,
  truncateText,
  formatNumber,
  formatDuration,
  debounce,
  throttle,
  categorizeError,
  createNetworkMonitor,
  safeStorage,
  createAsyncLock,
  clampNumber,
  isRTLLanguage,
  getTextDirection,
  preloadWithTimeout,
} from '../hardening.js'

describe('Hardening utilities', () => {
  describe('sanitizeText', () => {
    it('removes HTML tags', () => {
      expect(sanitizeText('<script>alert("xss")</script>')).toBe('alert("xss")')
      expect(sanitizeText('<div>Hello</div>')).toBe('Hello')
    })

    it('trims whitespace', () => {
      expect(sanitizeText('  hello  ')).toBe('hello')
    })

    it('limits length to 1000 chars', () => {
      const longText = 'a'.repeat(2000)
      expect(sanitizeText(longText).length).toBe(1000)
    })

    it('handles empty input', () => {
      expect(sanitizeText('')).toBe('')
      expect(sanitizeText(null)).toBe('')
      expect(sanitizeText(undefined)).toBe('')
    })

    it('handles non-string input', () => {
      expect(sanitizeText(123)).toBe('')
      expect(sanitizeText({})).toBe('')
    })
  })

  describe('truncateText', () => {
    it('returns short text unchanged', () => {
      expect(truncateText('Hello', 100)).toBe('Hello')
    })

    it('truncates long text with ellipsis', () => {
      const longText = 'a'.repeat(150)
      const result = truncateText(longText, 50)
      expect(result.length).toBe(50)
      expect(result.endsWith('...')).toBe(true)
    })

    it('uses default max length of 100', () => {
      const longText = 'a'.repeat(150)
      const result = truncateText(longText)
      expect(result.length).toBe(100)
    })

    it('handles empty input', () => {
      expect(truncateText('')).toBe('')
      expect(truncateText(null)).toBe('')
    })
  })

  describe('formatNumber', () => {
    it('formats integers', () => {
      expect(formatNumber(1234567)).toBe('1,234,567')
    })

    it('rounds decimals', () => {
      expect(formatNumber(1234.56)).toBe('1,235')
    })

    it('handles zero', () => {
      expect(formatNumber(0)).toBe('0')
    })

    it('returns 0 for invalid input', () => {
      expect(formatNumber('invalid')).toBe('0')
      expect(formatNumber(NaN)).toBe('0')
      expect(formatNumber(Infinity)).toBe('0')
    })

    it('supports different locales', () => {
      expect(formatNumber(1234.5, 'de-DE')).toBe('1.235')
    })
  })

  describe('formatDuration', () => {
    it('formats hours and minutes', () => {
      expect(formatDuration(3661)).toBe('1h 1m')
      expect(formatDuration(7200)).toBe('2h 0m')
    })

    it('formats minutes only', () => {
      expect(formatDuration(90)).toBe('1m')
      expect(formatDuration(300)).toBe('5m')
    })

    it('returns <1m for short durations', () => {
      expect(formatDuration(30)).toBe('<1m')
      expect(formatDuration(0)).toBe('<1m')
    })

    it('handles invalid input', () => {
      expect(formatDuration(-1)).toBe('<1m')
      expect(formatDuration('invalid')).toBe('<1m')
      expect(formatDuration(NaN)).toBe('<1m')
    })

    it('supports Spanish locale', () => {
      expect(formatDuration(3661, 'es')).toBe('1h 1m')
    })
  })

  describe('debounce', () => {
    it('delays function execution', async () => {
      const fn = vi.fn()
      const debounced = debounce(fn, 100)
      
      debounced()
      expect(fn).not.toHaveBeenCalled()
      
      await new Promise(resolve => setTimeout(resolve, 150))
      expect(fn).toHaveBeenCalledTimes(1)
    })

    it('resets timer on subsequent calls', async () => {
      const fn = vi.fn()
      const debounced = debounce(fn, 100)
      
      debounced()
      await new Promise(resolve => setTimeout(resolve, 50))
      debounced()
      
      await new Promise(resolve => setTimeout(resolve, 150))
      expect(fn).toHaveBeenCalledTimes(1)
    })

    it('passes arguments to debounced function', async () => {
      const fn = vi.fn()
      const debounced = debounce(fn, 10)
      
      debounced('arg1', 'arg2')
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(fn).toHaveBeenCalledWith('arg1', 'arg2')
    })
  })

  describe('throttle', () => {
    it('executes function immediately', () => {
      const fn = vi.fn()
      const throttled = throttle(fn, 100)
      
      throttled()
      expect(fn).toHaveBeenCalledTimes(1)
    })

    it('limits execution rate', async () => {
      const fn = vi.fn()
      const throttled = throttle(fn, 100)
      
      throttled()
      throttled()
      throttled()
      
      expect(fn).toHaveBeenCalledTimes(1)
      
      await new Promise(resolve => setTimeout(resolve, 150))
      throttled()
      expect(fn).toHaveBeenCalledTimes(2)
    })
  })

  describe('categorizeError', () => {
    it('categorizes network errors', () => {
      const result = categorizeError(new Error('Failed to fetch'))
      expect(result.type).toBe('network')
      expect(result.retryable).toBe(true)
    })

    it('categorizes timeout errors', () => {
      const result = categorizeError(new Error('Request timed out'))
      expect(result.type).toBe('timeout')
      expect(result.retryable).toBe(true)
    })

    it('categorizes 404 errors', () => {
      const result = categorizeError(new Error('HTTP 404'))
      expect(result.type).toBe('not-found')
    })

    it('categorizes server errors', () => {
      const result = categorizeError(new Error('HTTP 500'))
      expect(result.type).toBe('server')
    })

    it('categorizes dictionary errors', () => {
      const result = categorizeError(new Error('Dictionary failed to load'))
      expect(result.type).toBe('dictionary')
    })

    it('handles unknown errors', () => {
      const result = categorizeError(new Error('Something weird happened'))
      expect(result.type).toBe('unknown')
      expect(result.retryable).toBe(true)
    })

    it('handles null errors', () => {
      const result = categorizeError(null)
      expect(result.type).toBe('unknown')
    })
  })

  describe('safeStorage', () => {
    beforeEach(() => {
      localStorage.clear()
    })

    it('stores and retrieves values', () => {
      safeStorage.set('key1', { test: 'value' })
      const result = safeStorage.get('key1')
      expect(result).toEqual({ test: 'value' })
    })

    it('returns default value for missing keys', () => {
      const result = safeStorage.get('missing', 'default')
      expect(result).toBe('default')
    })

    it('removes values', () => {
      safeStorage.set('key2', 'value')
      safeStorage.remove('key2')
      expect(safeStorage.get('key2')).toBeNull()
    })

    it('handles storage errors gracefully', () => {
      vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new Error('Storage full')
      })
      
      const result = safeStorage.set('key', 'value')
      expect(result).toBe(false)
    })
  })

  describe('createAsyncLock', () => {
    it('allows first acquisition', async () => {
      const lock = createAsyncLock()
      const acquired = await lock.acquire()
      expect(acquired).toBe(true)
    })

    it('prevents double acquisition', async () => {
      const lock = createAsyncLock()
      await lock.acquire()
      const second = await lock.acquire()
      expect(second).toBe(false)
    })

    it('releases lock', async () => {
      const lock = createAsyncLock()
      await lock.acquire()
      lock.release()
      expect(lock.isLocked()).toBe(false)
    })
  })

  describe('clampNumber', () => {
    it('returns number within range', () => {
      expect(clampNumber(50, 0, 100, 0)).toBe(50)
    })

    it('clamps to minimum', () => {
      expect(clampNumber(-10, 0, 100, 0)).toBe(0)
    })

    it('clamps to maximum', () => {
      expect(clampNumber(150, 0, 100, 0)).toBe(100)
    })

    it('returns fallback for invalid input', () => {
      expect(clampNumber('invalid', 0, 100, 42)).toBe(42)
      expect(clampNumber(NaN, 0, 100, 42)).toBe(42)
    })

    it('returns default fallback when not specified', () => {
      expect(clampNumber('invalid', 0, 100)).toBe(0)
    })
  })

  describe('isRTLLanguage', () => {
    it('returns true for Arabic', () => {
      expect(isRTLLanguage('ar')).toBe(true)
      expect(isRTLLanguage('ar-SA')).toBe(true)
    })

    it('returns true for Hebrew', () => {
      expect(isRTLLanguage('he')).toBe(true)
    })

    it('returns false for English', () => {
      expect(isRTLLanguage('en')).toBe(false)
    })

    it('returns false for Spanish', () => {
      expect(isRTLLanguage('es')).toBe(false)
    })

    it('handles null/undefined', () => {
      expect(isRTLLanguage(null)).toBe(false)
      expect(isRTLLanguage(undefined)).toBe(false)
    })
  })

  describe('getTextDirection', () => {
    it('returns rtl for RTL languages', () => {
      expect(getTextDirection('ar')).toBe('rtl')
    })

    it('returns ltr for LTR languages', () => {
      expect(getTextDirection('en')).toBe('ltr')
    })
  })

  describe('preloadWithTimeout', () => {
    it.skip('preloads resource successfully', async () => {
      // Would need to mock fetch properly
      global.fetch = vi.fn().mockResolvedValue({ ok: true })
      
      const result = await preloadWithTimeout('/test.js', 5000)
      expect(result.ok).toBe(true)
    })

    it.skip('times out on slow response', async () => {
      global.fetch = vi.fn().mockImplementation(() => 
        new Promise(resolve => setTimeout(resolve, 20000))
      )
      
      await expect(preloadWithTimeout('/test.js', 100)).rejects.toThrow('timeout')
    })
  })
})
