import React, { useState, useEffect, useRef, useCallback } from 'react';
import { createClient } from '@supabase/supabase-js';
import { StorageManager } from './services/storage.js';
import { DictionaryManager } from './services/dictionary.js';
import { PrefetchManager } from './services/prefetch.js';
import { GodotLauncher } from './services/godotLauncher.js';
import { getTheme } from './services/theme.js';
import { getSettings } from './services/settings.js';
import { HomeScreen } from './screens/HomeScreen.jsx';
import { StatsScreen } from './screens/StatsScreen.jsx';
import { SettingsScreen } from './screens/SettingsScreen.jsx';
import { RulesScreen } from './screens/RulesScreen.jsx';
import { TutorialPrompt } from './components/TutorialPrompt.jsx';
import { 
  categorizeError, 
  createNetworkMonitor, 
  createAsyncLock,
  getTextDirection 
} from './services/hardening.js';
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
    currentScreen: 'home',
  }));

  const [showTutorialPrompt, setShowTutorialPrompt] = useState(false);
  const [isOnline, setIsOnline] = useState(true);
  const [errorDetails, setErrorDetails] = useState(null);
  const [notificationPermission, setNotificationPermission] = useState(
    typeof Notification !== 'undefined' ? Notification.permission : 'denied'
  );

  const landingRef = useRef(null);
  const storageManager = useRef(new StorageManager(supabase));
  const dictionaryManager = useRef(new DictionaryManager());
  const prefetchManager = useRef(null);
  const godotLauncher = useRef(null);
  const launchLock = useRef(createAsyncLock());
  const prefetchTriggerRef = useRef(null); // 'play-click' | null
  const networkMonitor = useRef(null);

  // Extracted launch sequence — called after prefetch finishes when triggered by play click
  const proceedFromPrefetchReady = useCallback(async () => {
    if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
      const perm = await Notification.requestPermission();
      setNotificationPermission(perm);
    }
    const hasCompletedTutorial = localStorage.getItem('word-loom-tutorial-completed') === 'true';
    const hasSkippedTutorial = localStorage.getItem('word-loom-tutorial-skipped') === 'true';
    if (!hasCompletedTutorial && !hasSkippedTutorial) {
      setShowTutorialPrompt(true);
      return;
    }
    await launchGame('game');
  }, []);

  // Memoized functions to avoid dependency warnings
  const loadHighScore = useCallback(async () => {
    try {
      const score = await storageManager.current.getHighScore();
      setState(prev => ({ ...prev, highScore: score }));
    } catch (error) {
      // Non-critical: high score is optional
      console.warn('Failed to load high score:', error);
    }
  }, []);

  const startPrefetch = useCallback(async () => {
    setState(prev => ({ ...prev, prefetchStatus: 'loading', prefetchProgress: 0, error: null }));

    try {
      prefetchManager.current = new PrefetchManager((progress) => {
        setState(prev => ({ ...prev, prefetchProgress: progress }));
      });

      const blobs = await prefetchManager.current.start();

      window.WORD_LOOM_BLOBS = {
        executableBlob: blobs.wasmBlob,
        mainPackBlob: blobs.pckBlob
      };

      const dictWords = dictionaryManager.current.parseWords(blobs.dict);
      dictionaryManager.current.cache.set('en', dictWords);

      setState(prev => ({ ...prev, prefetchStatus: 'ready' }));
      if (prefetchTriggerRef.current === 'play-click') {
        proceedFromPrefetchReady();
      }
    } catch (error) {
      console.error('Pre-fetch failed:', error);
      const categorized = categorizeError(error);
      setErrorDetails(categorized);
      setState(prev => ({
        ...prev,
        prefetchStatus: 'error',
        error: categorized.message,
      }));
    }
  }, []);

  useEffect(() => {
    loadHighScore();

    // Set up network monitoring
    networkMonitor.current = createNetworkMonitor((online) => {
      setIsOnline(online);
      // Auto-retry when coming back online
      if (online && state.prefetchStatus === 'error') {
        startPrefetch();
      }
    });

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

    return () => { 
      delete window.wordLoomGoHome;
      if (networkMonitor.current) {
        networkMonitor.current.destroy();
      }
    };
  }, [loadHighScore, startPrefetch, state.prefetchStatus]);

  async function handlePlayClick() {
    if (state.prefetchStatus === 'loading') {
      return;
    }
    if (state.prefetchStatus === 'idle') {
      // First click: start prefetching, auto-proceed when ready
      prefetchTriggerRef.current = 'play-click';
      startPrefetch();
      return;
    }
    // prefetchStatus === 'ready': proceed with launch
    await proceedFromPrefetchReady();
  }

  async function handleTutorialYes() {
    setShowTutorialPrompt(false);
    await launchGame('tutorial');
  }

  async function handleTutorialNo() {
    setShowTutorialPrompt(false);
    localStorage.setItem('word-loom-tutorial-skipped', 'true');
    await launchGame('game');
  }


  async function launchGame(launchScene) {
    // Prevent double-launch with async lock
    const acquired = await launchLock.current.acquire();
    if (!acquired) {
      console.warn('[launchGame] Launch already in progress, ignoring duplicate request');
      return;
    }

    setState(prev => ({ ...prev, transitioning: true, error: null }));

    // Set body background immediately to match game theme (eliminates black bars during transition)
    document.body.style.backgroundColor = THEME_BG[state.theme] || THEME_BG.dark;

    try {
      // CSS transition in HomeScreen handles the 500ms fade (opacity driven by state.transitioning)
      await new Promise(resolve => setTimeout(resolve, 500));

      const { executableBlob, mainPackBlob } = window.WORD_LOOM_BLOBS || {};
      
      godotLauncher.current = new GodotLauncher({
        executable: import.meta.env.VITE_GODOT_WASM || 'index',
        mainPack: import.meta.env.VITE_GODOT_PCK || 'index.pck',
        executableBlob,
        mainPackBlob,
        backgroundColor: THEME_BG[state.theme] || THEME_BG.dark,
      });

      await godotLauncher.current.initialize();

      // Get current language from user settings
      const currentSettings = getSettings();
      const language = currentSettings.language || 'en';
      
      // Load dictionary (from cache or fetch if needed)
      console.log(`[launchGame] Loading ${language} dictionary...`);
      let words = dictionaryManager.current.cache.get(language);
      
      if (!words) {
        console.log(`[launchGame] ${language} dictionary not in cache, fetching...`);
        words = await dictionaryManager.current.load(language);
      }
      
      console.log(`[launchGame] Retrieved ${language} words:`, {
        type: words?.constructor?.name,
        size: words?.size,
        isSet: words instanceof Set,
        isTruthy: !!words,
        keys: Array.from(words || []).slice(0, 5), // first 5 words
      });

      if (!words || words.size === 0) {
        const errMsg = `Dictionary failed to load: language=${language}, words=${typeof words}, size=${words?.size}`;
        console.error('[launchGame] VALIDATION FAILED:', errMsg);
        throw new Error(errMsg);
      }

      console.log(`[launchGame] ${language} dictionary validation PASSED, starting ${launchScene}...`);

      await godotLauncher.current.start({
        dictionary: { language: language, words },
        settings: { theme: state.theme },
        launchScene: launchScene,
      });

      // Game is loaded and ready — fire browser notification
      if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
        const notif = new Notification('wordfall is ready! 🎮', {
          body: 'Click here to start playing.',
          icon: '/apple-touch-icon.png',
          tag: 'word-loom-ready',
          requireInteraction: false,
        });
        notif.onclick = () => {
          window.focus();
          notif.close();
        };
      }

      window.saveHighScore = (score) => {
        storageManager.current.saveHighScore(score);
      };

      if (landingRef.current) {
        landingRef.current.style.display = 'none';
      }
    } catch (error) {
      console.error('[launchGame] Game start failed:', error);
      const categorized = categorizeError(error);
      setErrorDetails(categorized);
      setState(prev => ({ 
        ...prev, 
        transitioning: false, 
        error: categorized.message 
      }));

      if (landingRef.current) {
        landingRef.current.style.display = 'flex';
      }
    } finally {
      launchLock.current.release();
    }
  }

  const currentSettings = getSettings();
  const textDirection = getTextDirection(currentSettings.language);

  return (
    <div dir={textDirection}>
      {/* Offline indicator */}
      {!isOnline && (
        <div className="offline-indicator" role="alert" aria-live="polite">
          ⚠️ You are offline. Some features may not work.
        </div>
      )}
      
      {/* Skip link for accessibility */}
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>

      {state.currentScreen === 'home' && (
        <div ref={landingRef} id="main-content">
          <HomeScreen
            state={{ ...state, onRetry: startPrefetch, errorDetails }}
            onPlayClick={handlePlayClick}
            onStatsClick={() => setState(prev => ({ ...prev, currentScreen: 'stats' }))}
            onSettingsClick={() => setState(prev => ({ ...prev, currentScreen: 'settings' }))}
            onRulesClick={() => setState(prev => ({ ...prev, currentScreen: 'rules' }))}
            isOnline={isOnline}
          />
        </div>
      )}
      {state.currentScreen === 'stats' && (
        <StatsScreen
          theme={state.theme}
          onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
          language={currentSettings.language}
          isOnline={isOnline}
        />
      )}
      {state.currentScreen === 'settings' && (
        <SettingsScreen
          onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
          onThemeChange={(theme) => setState(prev => ({ ...prev, theme }))}
          language={currentSettings.language}
        />
      )}
      {state.currentScreen === 'rules' && (
        <RulesScreen
          theme={state.theme}
          language={currentSettings.language}
          onBack={() => setState(prev => ({ ...prev, currentScreen: 'home' }))}
        />
      )}

      <TutorialPrompt
        isOpen={showTutorialPrompt}
        onYes={handleTutorialYes}
        onNo={handleTutorialNo}
        language={currentSettings.language}
        theme={state.theme}
      />
    </div>
  )
}

export default App;
