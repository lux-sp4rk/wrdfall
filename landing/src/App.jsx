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
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'placeholder-key';
const supabase = createClient(supabaseUrl, supabaseKey);

function App() {
  // State management
  const [state, setState] = useState({
    prefetchStatus: 'idle', // idle | loading | ready | error
    prefetchProgress: 0,
    highScore: null,
    selectedLanguage: 'en',
    error: null,
    transitioning: false,
    theme: 'light',
  });

  // Service refs (persistent across renders)
  const landingRef = useRef(null);
  const storageManager = useRef(new StorageManager(supabase));
  const dictionaryManager = useRef(new DictionaryManager());
  const prefetchManager = useRef(null);
  const godotLauncher = useRef(null);

  // Load high score on mount
  useEffect(() => {
    loadHighScore();
    loadTheme();
    startPrefetch();
  }, []);

  /**
   * Load high score from storage
   */
  async function loadHighScore() {
    try {
      const score = await storageManager.current.getHighScore();
      setState(prev => ({ ...prev, highScore: score }));
    } catch (error) {
      console.warn('Failed to load high score:', error);
      // Non-critical - continue without high score
    }
  }

  /**
   * Load theme from storage
   */
  function loadTheme() {
    try {
      const theme = getTheme();
      setState(prev => ({ ...prev, theme }));
    } catch (error) {
      console.warn('Failed to load theme:', error);
      // Non-critical - continue with default theme
    }
  }

  /**
   * Start pre-fetch (Godot files + English dictionary)
   */
  async function startPrefetch() {
    setState(prev => ({
      ...prev,
      prefetchStatus: 'loading',
      prefetchProgress: 0,
      error: null,
    }));

    try {
      // Create prefetch manager with progress callback
      prefetchManager.current = new PrefetchManager((progress) => {
        setState(prev => ({ ...prev, prefetchProgress: progress }));
      });

      // Start parallel downloads
      await prefetchManager.current.start();

      // Load English dictionary
      await dictionaryManager.current.load('en');

      // Ready to play
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

  /**
   * Handle Play button click
   */
  async function handlePlayClick() {
    if (state.prefetchStatus !== 'ready') return;

    setState(prev => ({ ...prev, transitioning: true }));

    try {
      // Fade out landing page
      if (landingRef.current) {
        landingRef.current.style.opacity = '0';
      }

      // Wait for fade animation (500ms)
      await new Promise(resolve => setTimeout(resolve, 500));

      // Initialize Godot
      godotLauncher.current = new GodotLauncher({
        executable: '/index',
        mainPack: '/index.pck',
      });

      await godotLauncher.current.initialize();

      // Get dictionary for selected language
      const words = dictionaryManager.current.cache.get(state.selectedLanguage);

      // Start game
      await godotLauncher.current.start({
        dictionary: {
          language: state.selectedLanguage,
          words: words,
        },
        settings: {
          theme: 'light', // Default theme
        },
      });

      // Set up bridge: Godot → JS high score saving
      window.saveHighScore = (score) => {
        storageManager.current.saveHighScore(score);
      };

      // Hide landing page
      if (landingRef.current) {
        landingRef.current.style.display = 'none';
      }
    } catch (error) {
      console.error('Failed to start game:', error);
      setState(prev => ({
        ...prev,
        transitioning: false,
        error: error.message || 'Failed to start game',
      }));

      // Reset landing page visibility
      if (landingRef.current) {
        landingRef.current.style.opacity = '1';
        landingRef.current.style.display = 'flex';
      }
    }
  }

  /**
   * Handle language change
   */
  async function handleLanguageChange(language) {
    if (language === state.selectedLanguage) return;

    setState(prev => ({ ...prev, selectedLanguage: language }));

    // Lazy-load Spanish dictionary if not already cached
    if (language === 'es' && !dictionaryManager.current.cache.has('es')) {
      try {
        await dictionaryManager.current.load('es');
      } catch (error) {
        console.error('Failed to load Spanish dictionary:', error);
        setState(prev => ({
          ...prev,
          error: 'Failed to load Spanish dictionary',
        }));
      }
    }
  }

  // Determine if Play button should be enabled
  const canPlay = state.prefetchStatus === 'ready' && !state.transitioning;

  return (
    <div className={`landing-container theme-${state.theme}`} ref={landingRef}>
      <div className="landing-content">
        {/* Hero Section */}
        <div className="hero">
          <h1 className="logo">Word Loom</h1>
          <p className="tagline">Word-building meets Tetris</p>
        </div>

        {/* High Score Badge (retention hook) */}
        {state.highScore !== null && (
          <div className="high-score-badge">
            <div className="badge-label">Your Best</div>
            <div className="badge-score">{state.highScore.toLocaleString()}</div>
          </div>
        )}

        {/* Loading Progress */}
        {state.prefetchStatus === 'loading' && (
          <div className="progress-container">
            <div className="progress-bar">
              <div
                className="progress-fill"
                style={{ width: `${state.prefetchProgress}%` }}
              />
            </div>
            <div className="progress-text">
              Loading game files... {state.prefetchProgress}%
            </div>
          </div>
        )}

        {/* Error UI */}
        {state.error && (
          <div className="error-container">
            <div className="error-message">{state.error}</div>
            {state.prefetchStatus === 'error' && (
              <button className="retry-button" onClick={startPrefetch}>
                Retry
              </button>
            )}
          </div>
        )}

        {/* Play Button */}
        <button
          className="play-button"
          onClick={handlePlayClick}
          disabled={!canPlay}
        >
          {state.transitioning ? 'Starting...' : 'Play'}
        </button>

        {/* Language Selector */}
        <div className="language-selector">
          <button
            className={`language-button ${state.selectedLanguage === 'en' ? 'active' : ''}`}
            onClick={() => handleLanguageChange('en')}
          >
            English
          </button>
          <button
            className={`language-button ${state.selectedLanguage === 'es' ? 'active' : ''}`}
            onClick={() => handleLanguageChange('es')}
          >
            Español
          </button>
        </div>

        {/* How to Play */}
        <div className="how-to-play">
          <h2 className="how-to-title">How to Play</h2>
          <ul className="how-to-list">
            <li>Swipe letters in any direction to form words (3+ letters)</li>
            <li>Clear letters before the grid fills up</li>
            <li>Longer words = higher scores and slower drops</li>
            <li>Build combos with 4+ letter words for bonus multipliers</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default App;
