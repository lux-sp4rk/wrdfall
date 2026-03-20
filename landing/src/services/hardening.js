/**
 * Hardening utilities for Word Loom landing page
 * Handles edge cases, errors, i18n, and accessibility
 */

/**
 * Text sanitization to prevent XSS and handle special characters
 */
export function sanitizeText(text) {
  if (!text || typeof text !== 'string') return ''
  return text
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .trim()
    .slice(0, 1000) // Limit length
}

/**
 * Truncate text with ellipsis
 */
export function truncateText(text, maxLength = 100) {
  if (!text || typeof text !== 'string') return ''
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength - 3) + '...'
}

/**
 * Format numbers with locale support
 */
export function formatNumber(num, locale = 'en-US') {
  if (typeof num !== 'number' || !Number.isFinite(num)) return '0'
  return new Intl.NumberFormat(locale).format(Math.round(num))
}

/**
 * Format time duration with internationalization
 */
export function formatDuration(seconds, locale = 'en') {
  if (typeof seconds !== 'number' || !Number.isFinite(seconds) || seconds < 0) {
    return locale === 'es' ? '<1m' : '<1m'
  }
  
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  const translations = {
    en: { h: 'h', m: 'm' },
    es: { h: 'h', m: 'm' },
  }
  
  const t = translations[locale] || translations.en
  
  if (hours > 0) {
    return `${hours}${t.h} ${minutes}${t.m}`
  }
  if (minutes > 0) {
    return `${minutes}${t.m}`
  }
  return `<1${t.m}`
}

/**
 * Debounce function to prevent rapid-fire calls
 */
export function debounce(fn, delay = 300) {
  let timeoutId
  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn(...args), delay)
  }
}

/**
 * Throttle function to limit execution rate
 */
export function throttle(fn, limit = 100) {
  let inThrottle
  return (...args) => {
    if (!inThrottle) {
      fn(...args)
      inThrottle = true
      setTimeout(() => (inThrottle = false), limit)
    }
  }
}

/**
 * Error categorization for better UX
 */
export function categorizeError(error) {
  if (!error) return { type: 'unknown', message: 'An unknown error occurred', retryable: false }
  
  const message = error.message || String(error)
  
  // Network errors
  if (message.includes('fetch') || 
      message.includes('network') || 
      message.includes('Failed to fetch') ||
      message.includes('net::ERR')) {
    return {
      type: 'network',
      message: 'Connection failed. Please check your internet and try again.',
      retryable: true
    }
  }
  
  // Timeout errors
  if (message.includes('timeout') || message.includes('timed out')) {
    return {
      type: 'timeout',
      message: 'Request timed out. Please try again.',
      retryable: true
    }
  }
  
  // HTTP errors
  if (message.includes('HTTP 404')) {
    return {
      type: 'not-found',
      message: 'Game files not found. Please try again later.',
      retryable: true
    }
  }
  
  if (message.includes('HTTP 5') || message.includes('HTTP 500')) {
    return {
      type: 'server',
      message: 'Server error. Please try again later.',
      retryable: true
    }
  }
  
  // Dictionary errors
  if (message.includes('dictionary') || message.includes('Dictionary')) {
    return {
      type: 'dictionary',
      message: 'Failed to load word list. Please try again.',
      retryable: true
    }
  }
  
  // Pre-fetch errors
  if (message.includes('Pre-fetch')) {
    return {
      type: 'prefetch',
      message: 'Failed to load game files. Please try again.',
      retryable: true
    }
  }
  
  return {
    type: 'unknown',
    message: message.slice(0, 200), // Limit error message length
    retryable: true
  }
}

/**
 * Network status monitor
 */
export function createNetworkMonitor(onChange) {
  const handleOnline = () => onChange(true)
  const handleOffline = () => onChange(false)
  
  window.addEventListener('online', handleOnline)
  window.addEventListener('offline', handleOffline)
  
  return {
    isOnline: () => navigator.onLine,
    destroy: () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }
}

/**
 * Safe localStorage wrapper with error handling
 */
export const safeStorage = {
  get(key, defaultValue = null) {
    try {
      const item = localStorage.getItem(key)
      return item ? JSON.parse(item) : defaultValue
    } catch {
      return defaultValue
    }
  },
  
  set(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value))
      return true
    } catch {
      return false
    }
  },
  
  remove(key) {
    try {
      localStorage.removeItem(key)
      return true
    } catch {
      return false
    }
  }
}

/**
 * Race condition prevention - prevents double submission
 */
export function createAsyncLock() {
  let isLocked = false
  
  return {
    async acquire() {
      if (isLocked) return false
      isLocked = true
      return true
    },
    release() {
      isLocked = false
    },
    isLocked: () => isLocked
  }
}

/**
 * Validate and clamp numeric values
 */
export function clampNumber(value, min, max, defaultValue = 0) {
  const num = Number(value)
  if (!Number.isFinite(num)) return defaultValue
  return Math.max(min, Math.min(max, num))
}

/**
 * Detect RTL languages
 */
export function isRTLLanguage(locale) {
  const rtlLanguages = ['ar', 'he', 'fa', 'ur']
  return rtlLanguages.some(lang => locale?.startsWith(lang))
}

/**
 * Get text direction attribute
 */
export function getTextDirection(locale) {
  return isRTLLanguage(locale) ? 'rtl' : 'ltr'
}

/**
 * Preload critical resources with timeout
 */
export async function preloadWithTimeout(url, timeoutMs = 10000) {
  return Promise.race([
    fetch(url, { method: 'HEAD' }),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Preload timeout')), timeoutMs)
    )
  ])
}
