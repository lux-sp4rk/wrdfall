import React, { useState, useEffect, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { StorageManager } from './services/storage.js';
import { DictionaryManager } from './services/dictionary.js';
import { PrefetchManager } from './services/prefetch.js';
import { GodotLauncher } from './services/godotLauncher.js';
import { getTheme } from './services/theme.js';
import './App.css';

// Initialize Supabase client
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseKey = import.meta.env.VITE_SUPABASE_KEY || 'placeholder-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Theme background colors (must match ThemeConstants.gd)
const THEME_BG = {
  dark: '#2B3D4F',
  light: '#F5F2E8',
};

function App() {
  const [state, setState] = useState(() => ({
    prefetchStatus: 'idle', // idle | loading | ready | error
    prefetchProgress: 0,
    highScore: null,
    error: null,
    transitioning: false,
    theme: getTheme(),
  }));

  const landingRef = useRef(null);
  const storageManager = useRef(new StorageManager(supabase));
  const dictionaryManager = useRef(new DictionaryManager());
  const prefetchManager = useRef(null);
  const godotLauncher = useRef(null);

  useEffect(() => {
    loadHighScore();
    startPrefetch();
  }, []);

  async function loadHighScore() {
    try {
      const score = await storageManager.current.getHighScore();
      setState(prev => ({ ...prev, highScore: score }));
    } catch (error) {
      // Non-critical
    }
  }

  async function startPrefetch() {
    setState(prev => ({ ...prev, prefetchStatus: 'loading', prefetchProgress: 0, error: null }));

    try {
      prefetchManager.current = new PrefetchManager((progress) => {
        setState(prev => ({ ...prev, prefetchProgress: progress }));
      });

      const blobs = await prefetchManager.current.start();
      
      // Store Blobs as Object URLs to prevent double-download in Godot
      window.WORD_LOOM_BLOBS = {
        wasm: URL.createObjectURL(blobs.wasm),
        pck: URL.createObjectURL(blobs.pck)
      };

      await dictionaryManager.current.load('en');

      setState(prev => ({ ...prev, prefetchStatus: 'ready' }));
    } catch (error) {
      console.error('Pre-fetch failed:', error);
      setState(prev => ({
        ...prev,
        prefetchStatus: 'error',
        error: error.message || 'Failed to load game files',
      }));
    }
  }

  async function handlePlayClick() {
    if (state.prefetchStatus !== 'ready') return;

    setState(prev => ({ ...prev, transitioning: true }));

    // Set body background immediately to match game theme (eliminates black bars during transition)
    document.body.style.backgroundColor = THEME_BG[state.theme] || THEME_BG.dark;

    try {
      if (landingRef.current) {
        landingRef.current.style.opacity = '0';
      }

      await new Promise(resolve => setTimeout(resolve, 500));

      const { wasm, pck } = window.WORD_LOOM_BLOBS || {};
      
      godotLauncher.current = new GodotLauncher({
        executable: wasm || '/index',
        mainPack: pck || '/index.pck',
      });

      await godotLauncher.current.initialize();

      const words = dictionaryManager.current.cache.get('en');

      await godotLauncher.current.start({
        dictionary: { language: 'en', words },
        settings: { theme: state.theme },
      });

      window.saveHighScore = (score) => {
        storageManager.current.saveHighScore(score);
      };

      if (landingRef.current) {
        landingRef.current.style.display = 'none';
      }
    } catch (error) {
      console.error('Failed to start game:', error);
      setState(prev => ({ ...prev, transitioning: false, error: error.message || 'Failed to start game' }));

      if (landingRef.current) {
        landingRef.current.style.opacity = '1';
        landingRef.current.style.display = 'flex';
      }
    }
  }

  const canPlay = state.prefetchStatus === 'ready' && !state.transitioning;

  return (
    <div className={`landing-container theme-${state.theme}`} ref={landingRef}>
      <div className="landing-content">
        <div className="hero">
          <h1 className="logo">Word Loom</h1>
          <p className="tagline">Word-building meets Tetris</p>
        </div>

        {state.highScore !== null && (
          <div className="high-score-badge">
            <div className="badge-label">Your Best</div>
            <div className="badge-score">{state.highScore.toLocaleString()}</div>
          </div>
        )}

        {state.prefetchStatus === 'loading' && (
          <div className="progress-container">
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${state.prefetchProgress}%` }} />
            </div>
            <div className="progress-text">Loading... {state.prefetchProgress}%</div>
          </div>
        )}

        {state.error && (
          <div className="error-container">
            <div className="error-message">{state.error}</div>
            {state.prefetchStatus === 'error' && (
              <button className="retry-button" onClick={startPrefetch}>Retry</button>
            )}
          </div>
        )}

        <button className="play-button" onClick={handlePlayClick} disabled={!canPlay}>
          {state.transitioning ? 'Starting...' : 'Play'}
        </button>
      </div>
    </div>
  );
}

export default App;
