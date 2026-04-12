import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import React from 'react';
import App from '../App.jsx';

// Mock all the services and dependencies
vi.mock('@supabase/supabase-js', () => ({
  createClient: () => ({
    from: () => ({
      select: () => ({ eq: () => ({ maybeSingle: () => Promise.resolve({ data: null, error: null }) }) }),
      upsert: () => Promise.resolve({ error: null }),
    }),
  }),
}));

vi.mock('../services/storage.js', () => ({
  StorageManager: class {
    async getHighScore() { return null; }
  },
}));

vi.mock('../services/dictionary.js', () => ({
  DictionaryManager: class {
    cache = new Map();
    parseWords() { return new Set(); }
  },
}));

vi.mock('../services/prefetch.js', () => ({
  PrefetchManager: class {
    constructor(onProgress) { this.onProgress = onProgress; }
    async start() {
      return {
        wasmBlob: new Blob(),
        pckBlob: new Blob(),
        dict: 'word1\nword2',
      };
    }
  },
}));

vi.mock('../services/godotLauncher.js', () => ({
  GodotLauncher: class {
    async initialize() { return {}; }
    async start() { }
    stop() { }
  },
}));

vi.mock('../services/theme.js', () => ({
  getTheme: () => 'dark',
}));

vi.mock('../services/settings.js', () => ({
  getSettings: () => ({ language: 'en', theme: 'dark' }),
}));

vi.mock('../services/hardening.js', () => ({
  categorizeError: (e) => ({ type: 'unknown', message: e.message, retryable: true }),
  createNetworkMonitor: (onChange) => ({
    isOnline: () => true,
    destroy: () => {},
  }),
  createAsyncLock: () => ({
    async acquire() { return true; },
    release() { },
    isLocked: () => false,
  }),
  getTextDirection: () => 'ltr',
}));

describe('App', () => {
  beforeEach(() => {
    // Mock localStorage
    const mockStorage = {};
    global.localStorage = {
      getItem: (key) => mockStorage[key] || null,
      setItem: (key, value) => { mockStorage[key] = value; },
      removeItem: (key) => { delete mockStorage[key]; },
    };

    // Mock window properties
    global.window.WORD_LOOM_BLOBS = null;
  });

  it('renders without crashing', () => {
    const { container } = render(<App />);
    expect(container.firstChild).toBeTruthy();
  });
});
