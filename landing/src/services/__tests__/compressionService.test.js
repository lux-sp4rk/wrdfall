import { describe, it, expect, vi, beforeEach } from 'vitest'
import { CompressionService } from '../compressionService.js'

describe('CompressionService', () => {
  let service

  beforeEach(() => {
    service = new CompressionService()
    vi.clearAllMocks()
  })

  describe('constructor', () => {
    it('creates compression service instance', () => {
      expect(service).toBeInstanceOf(CompressionService)
    })

    it('initializes with empty cache', () => {
      expect(service.decompressed.size).toBe(0)
    })

    it('marks pako as not loaded initially', () => {
      expect(service.pako).toBeNull()
      expect(service.pakoLoadFailed).toBe(false)
    })
  })

  describe('loadPako', () => {
    it('loads pako library', async () => {
      const pako = await service.loadPako()
      expect(pako).toBeDefined()
      expect(service.pako).toBe(pako)
    })

    it('returns cached pako if already loaded', async () => {
      const pako1 = await service.loadPako()
      const pako2 = await service.loadPako()
      expect(pako1).toBe(pako2)
    })

    it('does not retry after failure', async () => {
      service.pakoLoadFailed = true
      await expect(service.loadPako()).rejects.toThrow('pako loading previously failed')
    })
  })

  describe('caching', () => {
    it('returns cached data if available', async () => {
      const testData = 'test dictionary data'
      // Cache key format is "language.ext" based on the formats array order (.br first)
      service.decompressed.set('test.br', testData)
      
      // Mock fetch to verify it's not called when cache hit
      const fetchSpy = vi.fn().mockResolvedValue({ ok: false })
      global.fetch = fetchSpy
      
      const result = await service.fetchDictionary('test')
      expect(result).toBe(testData)
      // Should not call fetch when data is cached
      expect(fetchSpy).not.toHaveBeenCalled()
    })
  })
})
