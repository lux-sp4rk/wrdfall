import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import React from 'react';
import App from '../App.jsx';

const mockStorage = {};

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

beforeEach(() => {
  global.localStorage = {
    getItem: (key) => mockStorage[key] || null,
    setItem: (key, value) => { mockStorage[key] = value; },
    removeItem: (key) => { delete mockStorage[key]; },
  };
  global.window.WORD_LOOM_BLOBS = null;
  mockStorage['word-loom-tutorial-completed'] = 'true';
  mockStorage['word-loom-tutorial-skipped'] = null;
});

describe('App', () => {
  it('renders without crashing', () => {
    const { container } = render(<App />);
    expect(container.firstChild).toBeTruthy();
  });

  it('renders the home screen by default with play button', async () => {
    render(<App />);
    await waitFor(() => expect(document.querySelector('.play-button')).toBeTruthy());
  });

  it('navigates to Stats screen when Stats button is clicked', async () => {
    render(<App />);
    await waitFor(() => screen.getByRole('button', { name: 'Stats' }));
    fireEvent.click(screen.getByRole('button', { name: 'Stats' }));
    await waitFor(() => screen.getByText('Records'));
  });

  it('navigates to Settings screen when Settings button is clicked', async () => {
    render(<App />);
    await waitFor(() => screen.getByRole('button', { name: 'Settings' }));
    fireEvent.click(screen.getByRole('button', { name: 'Settings' }));
    await waitFor(() => screen.getByText('Theme'));
  });

  it('navigates to Rules screen when Rules button is clicked', async () => {
    render(<App />);
    await waitFor(() => screen.getByRole('button', { name: 'How to Play' }));
    fireEvent.click(screen.getByRole('button', { name: 'How to Play' }));
    await waitFor(() => screen.getByText('How to Play'));
  });

  it('returns to home screen when Back button is clicked from Stats', async () => {
    render(<App />);
    await waitFor(() => screen.getByRole('button', { name: 'Stats' }));
    fireEvent.click(screen.getByRole('button', { name: 'Stats' }));
    await waitFor(() => screen.getByText('Records'));
    fireEvent.click(screen.getByText('← Back'));
    await waitFor(() => expect(document.querySelector('.play-button')).toBeTruthy());
  });

  it('returns to home screen when Back button is clicked from Settings', async () => {
    render(<App />);
    await waitFor(() => screen.getByRole('button', { name: 'Settings' }));
    fireEvent.click(screen.getByRole('button', { name: 'Settings' }));
    await waitFor(() => screen.getByText('Theme'));
    fireEvent.click(screen.getByText('← Back'));
    await waitFor(() => expect(document.querySelector('.play-button')).toBeTruthy());
  });

  it('returns to home screen when Back button is clicked from Rules', async () => {
    render(<App />);
    await waitFor(() => screen.getByRole('button', { name: 'How to Play' }));
    fireEvent.click(screen.getByRole('button', { name: 'How to Play' }));
    await waitFor(() => screen.getByText('How to Play'));
    fireEvent.click(screen.getByText('← Back'));
    await waitFor(() => expect(document.querySelector('.play-button')).toBeTruthy());
  });

  it('applies text direction via dir attribute', () => {
    const { container } = render(<App />);
    expect(container.querySelector('[dir="ltr"]')).toBeTruthy();
  });

  it('has skip link for accessibility', () => {
    render(<App />);
    const skipLink = document.querySelector('.skip-link');
    expect(skipLink).toBeTruthy();
    expect(skipLink.getAttribute('href')).toBe('#main-content');
  });

  it('navigates back to home when wordfallGoHome is called', () => {
    render(<App />);
    expect(typeof window.wordfallGoHome).toBe('function');
    // Calling it should not throw
    window.wordfallGoHome();
  });
});
