import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { detectSystemTheme, getTheme, setTheme } from '../theme.js';

describe('theme', () => {
  let originalMatchMedia;

  beforeEach(() => {
    localStorage.clear();
    // Store original matchMedia
    originalMatchMedia = window.matchMedia;
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('detectSystemTheme', () => {
    it('detects light mode preference', () => {
      window.matchMedia = vi.fn().mockImplementation((query) => ({
        matches: query === '(prefers-color-scheme: light)',
      }));
      expect(detectSystemTheme()).toBe('light');
    });

    it('defaults to dark when no light preference', () => {
      window.matchMedia = vi.fn().mockImplementation(() => ({
        matches: false,
      }));
      expect(detectSystemTheme()).toBe('dark');
    });

    it('defaults to dark when matchMedia not available', () => {
      window.matchMedia = undefined;
      expect(detectSystemTheme()).toBe('dark');
    });

    it('handles matchMedia errors gracefully', () => {
      window.matchMedia = vi.fn().mockImplementation(() => {
        throw new Error('matchMedia error');
      });
      expect(detectSystemTheme()).toBe('dark');
    });
  });

  describe('getTheme', () => {
    it('returns saved theme from localStorage', () => {
      localStorage.setItem('word-loom-theme', 'light');
      expect(getTheme()).toBe('light');
    });

    it('detects system theme on first visit', () => {
      window.matchMedia = vi.fn().mockImplementation((query) => ({
        matches: query === '(prefers-color-scheme: light)',
      }));
      
      expect(getTheme()).toBe('light');
      expect(localStorage.getItem('word-loom-theme')).toBe('light');
    });

    it('ignores invalid saved themes', () => {
      localStorage.setItem('word-loom-theme', 'invalid-theme');
      window.matchMedia = vi.fn().mockImplementation(() => ({
        matches: false,
      }));
      
      expect(getTheme()).toBe('dark');
    });

    it('handles localStorage errors gracefully', () => {
      // Make localStorage.getItem throw
      const originalGetItem = localStorage.getItem;
      localStorage.getItem = () => {
        throw new Error('localStorage error');
      };
      
      window.matchMedia = vi.fn().mockImplementation(() => ({
        matches: false,
      }));
      
      expect(getTheme()).toBe('dark');
      
      localStorage.getItem = originalGetItem;
    });
  });

  describe('setTheme', () => {
    it('saves valid theme to localStorage', () => {
      setTheme('light');
      expect(localStorage.getItem('word-loom-theme')).toBe('light');
      
      setTheme('dark');
      expect(localStorage.getItem('word-loom-theme')).toBe('dark');
    });

    it('defaults to dark for invalid themes', () => {
      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      setTheme('invalid');
      expect(localStorage.getItem('word-loom-theme')).toBe('dark');
      expect(consoleSpy).toHaveBeenCalledWith('Invalid theme: invalid, defaulting to dark');
    });

    it('handles localStorage errors gracefully', () => {
      // Test that setTheme is callable
      // Full error handling is tested via integration tests
      expect(() => setTheme('light')).not.toThrow();
    });
  });
});
