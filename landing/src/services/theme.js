/**
 * ThemeService - Detect and manage theme preference
 *
 * Strategy:
 * - First visit: Detect OS light mode preference (defaults to dark)
 * - Subsequent visits: Read from localStorage
 * - Sync with Godot via shared localStorage key
 */

const THEME_KEY = 'word-loom-theme';
const THEME_LIGHT = 'light';
const THEME_DARK = 'dark';

/**
 * Detect system dark mode preference
 */
export function detectSystemTheme() {
  try {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) {
      return THEME_LIGHT;
    }
  } catch (error) {
    console.warn('Failed to detect system theme:', error);
  }
  return THEME_DARK;
}

/**
 * Get current theme (reads localStorage, falls back to OS preference)
 */
export function getTheme() {
  try {
    // Try localStorage first
    const savedTheme = localStorage.getItem(THEME_KEY);

    // Validate saved theme
    if (savedTheme === THEME_LIGHT || savedTheme === THEME_DARK) {
      return savedTheme;
    }

    // First visit: detect OS preference and save
    const systemTheme = detectSystemTheme();
    localStorage.setItem(THEME_KEY, systemTheme);
    return systemTheme;
  } catch (error) {
    // localStorage not available (private browsing)
    console.warn('localStorage not available, using system theme:', error);
    return detectSystemTheme();
  }
}

/**
 * Set theme (for future use if React needs to change theme)
 */
export function setTheme(theme) {
  if (theme !== THEME_LIGHT && theme !== THEME_DARK) {
    console.warn(`Invalid theme: ${theme}, defaulting to dark`);
    theme = THEME_DARK;
  }

  try {
    localStorage.setItem(THEME_KEY, theme);
  } catch (error) {
    console.warn('Failed to save theme to localStorage:', error);
  }
}
