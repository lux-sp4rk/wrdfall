import React, { useState, useEffect, useRef } from 'react';
import { createClient } from '@supabase/supabase-js';
import { StorageManager } from './services/storage.js';
import { DictionaryManager } from './services/dictionary.js';
import { PrefetchManager } from './services/prefetch.js';
import { GodotLauncher } from './services/godotLauncher.js';
import { getTheme } from './services/theme.js';
import { HomeScreen } from './screens/HomeScreen.jsx';
import { StatsScreen } from './screens/StatsScreen.jsx';
import { SettingsScreen } from './screens/SettingsScreen.jsx';
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
    showProgress: false,
    currentScreen: 'home',
  }));

  const landingRef = useRef(null);
  const storageManager = useRef(new StorageManager(supabase));
  const dictionaryManager = useRef(new DictionaryManager());
  const prefetchManager = useRef(null);
  const godotLauncher = useRef(null);

  useEffect(() => {
    loadHighScore();
    startPrefetch();

    window.wordLoomGoHome = () => {
      if (godotLauncher.current) {
        godotLauncher.current.stop();
        godotLauncher.current = null;
      }
      if (landingRef.current) {
        landingRef.current.style.display = 'flex';
      }
      document.body.style.backgroundColor = '';
      setState(prev => ({ ...prev, transitioning: false }));
    };

    return () => { delete window.wordLoomGoHome; };
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

    // Show progress if it takes more than 1.5s (likely not cached)
    const timer = setTimeout(() => {
      setState(prev => ({ ...prev, showProgress: true }));
    }, 1500);

    try {
      prefetchManager.current = new PrefetchManager((progress) => {
        setState(prev => ({ ...prev, prefetchProgress: progress }));
      });

      const blobs = await prefetchManager.current.start();
      
      // Pass direct paths to GodotLauncher.
      // NOTE: 'wasm' is the Godot ENGINE BASE NAME (no extension).
      // GodotLauncher strips any '.wasm' suffix before calling engine.init(),
      // Godot internally appends '.wasm'. Passing 'index.wasm' would
      // cause Godot to fetch 'index.wasm.wasm' → 404 → HTML → magic word error.
      window.WORD_LOOM_BLOBS = {
        wasm: import.meta.env.VITE_GODOT_WASM || 'index',
        pck: import.meta.env.VITE_GODOT_PCK || 'index.pck'
      };

      await dictionaryManager.current.load('en');

      clearTimeout(timer);
      setState(prev => ({ ...prev, prefetchStatus: 'ready' }));
    } catch (error) {
      clearTimeout(timer);
      console.error('Pre-fetch failed:', error);
      setState(prev => ({
        ...prev,
        prefetchStatus: 'error',
        error: error.message || 'Failed to load game files',
      }));
    }
  }

  async function handlePlayClick() {
    if (state.prefetchStatus === 'loading') {
      setState(prev => ({ ...prev, showProgress: true }));
      return;
    }
    if (state.prefetchStatus !== 'ready') return;

    setState(prev => ({ ...prev, transitioning: true }));

    // Set body background immediately to match game theme (eliminates black bars during transition)
    document.body.style.backgroundColor = THEME_BG[state.theme] || THEME_BG.dark;

    try {
      // CSS transition in HomeScreen handles the 500ms fade (opacity driven by state.transitioning)
      await new Promise(resolve => setTimeout(resolve, 500));

      const { wasm, pck } = window.WORD_LOOM_BLOBS || {};
      
      godotLauncher.current = new GodotLauncher({
        executable: wasm || 'index',
        mainPack: pck || 'index.pck',
        backgroundColor: THEME_BG[state.theme] || THEME_BG.dark,
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
        landingRef.current.style.display = 'flex';
      }
    }
  }

  return (
    <>
      {state.currentScreen === 'home' && (
        <div ref={landingRef}>
          <HomeScreen
            state={{ ...state, onRetry: startPrefetch }}
            onPlayClick={handlePlayClick}
            onStatsClick={() => setState(prev => ({ ...prev, currentScreen: 'stats' }))}
            onSettingsClick={() => setState(prev => ({ ...prev, currentScreen: 'settings' }))}
          />
        </div>
      )}
      {state.currentScreen === 'stats' && (
        <StatsScreen
          theme={state.theme}
          onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
        />
      )}
      {state.currentScreen === 'settings' && (
        <SettingsScreen
          onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
          onThemeChange={(theme) => setState(prev => ({ ...prev, theme }))}
        />
      )}
    </>
  )
}

export default App;
