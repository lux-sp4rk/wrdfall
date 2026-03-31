import { describe, it, expect, vi, beforeEach } from 'vitest'
import { DictionaryManager } from '../dictionary.js'

describe('DictionaryManager', () => {
  let manager

  beforeEach(() => {
    manager = new DictionaryManager()
    vi.clearAllMocks()
  })

  describe('constructor', () => {
    it('creates dictionary manager instance', () => {
      expect(manager).toBeInstanceOf(DictionaryManager)
    })

    it('initializes with empty cache', () => {
      expect(manager.cache.size).toBe(0)
    })

    it('initializes with empty loading map', () => {
      expect(manager.loading.size).toBe(0)
    })
  })

  describe('load', () => {
    it('throws error for invalid language code', async () => {
      await expect(manager.load('invalid')).rejects.toThrow('Invalid language code')
      await expect(manager.load('123')).rejects.toThrow('Invalid language code')
      await expect(manager.load('e')).rejects.toThrow('Invalid language code')
    })

    it('validates 2-letter language codes', async () => {
      // Should not throw for valid codes
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        text: vi.fn().mockResolvedValue('HELLO\nWORLD'),
      })

      // These should not throw
      await expect(manager.load('en')).rejects.not.toThrow('Invalid language code')
      await expect(manager.load('es')).rejects.not.toThrow('Invalid language code')
    })

    it('returns cached data if available', async () => {
      const testSet = new Set(['HELLO', 'WORLD'])
      manager.cache.set('en', testSet)
      
      const result = await manager.load('en')
      expect(result).toBe(testSet)
    })
  })

  describe('parseWords', () => {
    it('returns empty set for empty text', () => {
      const result = manager.parseWords('')
      expect(result.size).toBe(0)
    })

    it('returns empty set for null text', () => {
      const result = manager.parseWords(null)
      expect(result.size).toBe(0)
    })

    it('returns empty set for undefined text', () => {
      const result = manager.parseWords(undefined)
      expect(result.size).toBe(0)
    })

    it('parses words from text', () => {
      const text = 'HELLO\nWORLD\nTEST'
      const result = manager.parseWords(text)
      expect(result.size).toBe(3)
      expect(result.has('HELLO')).toBe(true)
      expect(result.has('WORLD')).toBe(true)
      expect(result.has('TEST')).toBe(true)
    })

    it('converts words to uppercase', () => {
      const text = 'hello\nWorld\nTeSt'
      const result = manager.parseWords(text)
      expect(result.has('HELLO')).toBe(true)
      expect(result.has('WORLD')).toBe(true)
      expect(result.has('TEST')).toBe(true)
    })

    it('skips empty lines', () => {
      const text = 'HELLO\n\nWORLD\n\nTEST'
      const result = manager.parseWords(text)
      expect(result.size).toBe(3)
    })

    it('skips comment lines starting with #', () => {
      const text = 'HELLO\n# This is a comment\nWORLD'
      const result = manager.parseWords(text)
      expect(result.size).toBe(2)
      expect(result.has('# This is a comment')).toBe(false)
    })

    it('trims whitespace from words', () => {
      const text = '  HELLO  \n  WORLD  '
      const result = manager.parseWords(text)
      expect(result.has('HELLO')).toBe(true)
      expect(result.has('WORLD')).toBe(true)
    })
  })

  describe('isValidWord', () => {
    it('returns false when dictionary not loaded', async () => {
      const result = await manager.isValidWord('HELLO', 'en')
      expect(result).toBe(false)
    })

    it('returns true for valid word', async () => {
      const words = new Set(['HELLO', 'WORLD'])
      manager.cache.set('en', words)
      
      const result = await manager.isValidWord('hello', 'en')
      expect(result).toBe(true)
    })

    it('returns false for invalid word', async () => {
      const words = new Set(['HELLO', 'WORLD'])
      manager.cache.set('en', words)
      
      const result = await manager.isValidWord('INVALID', 'en')
      expect(result).toBe(false)
    })

    it('is case insensitive', async () => {
      const words = new Set(['HELLO'])
      manager.cache.set('en', words)
      
      expect(await manager.isValidWord('hello', 'en')).toBe(true)
      expect(await manager.isValidWord('HELLO', 'en')).toBe(true)
      expect(await manager.isValidWord('Hello', 'en')).toBe(true)
    })
  })

  describe('clear', () => {
    it('clears the cache', () => {
      manager.cache.set('en', new Set(['HELLO']))
      expect(manager.cache.size).toBe(1)
      
      manager.clear()
      expect(manager.cache.size).toBe(0)
    })
  })
})
