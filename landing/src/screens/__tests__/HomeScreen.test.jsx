import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';
import { HomeScreen } from '../HomeScreen.jsx';

describe('HomeScreen', () => {
  const mockState = {
    theme: 'light',
    highScore: 0,
    transitioning: false,
    prefetchStatus: 'idle',
    error: null,
    errorDetails: null,
    onRetry: vi.fn(),
  };

  const mockHandlers = {
    onPlayClick: vi.fn(),
    onStatsClick: vi.fn(),
    onSettingsClick: vi.fn(),
    onRulesClick: vi.fn(),
  };

  it('renders basic structure', () => {
    render(<HomeScreen state={mockState} {...mockHandlers} />);
    
    expect(screen.getByText('Wordfall')).toBeInTheDocument();
    expect(screen.getByText('Word-building meets Tetris')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Play game' })).toBeInTheDocument();
  });

  it('displays high score when available', () => {
    const stateWithScore = { ...mockState, highScore: 1500 };
    render(<HomeScreen state={stateWithScore} {...mockHandlers} />);
    
    expect(screen.getByText(/Best:/)).toHaveTextContent('Best: 1,500');
  });

  it('calls onPlayClick when play button clicked', () => {
    render(<HomeScreen state={mockState} {...mockHandlers} />);
    
    fireEvent.click(screen.getByRole('button', { name: 'Play game' }));
    expect(mockHandlers.onPlayClick).toHaveBeenCalledTimes(1);
  });

  it('calls onStatsClick when stats button clicked', () => {
    render(<HomeScreen state={mockState} {...mockHandlers} />);
    
    fireEvent.click(screen.getByText('Stats'));
    expect(mockHandlers.onStatsClick).toHaveBeenCalledTimes(1);
  });

  it('calls onSettingsClick when settings button clicked', () => {
    render(<HomeScreen state={mockState} {...mockHandlers} />);
    
    fireEvent.click(screen.getByText('Settings'));
    expect(mockHandlers.onSettingsClick).toHaveBeenCalledTimes(1);
  });

  it('calls onRulesClick when rules button clicked', () => {
    render(<HomeScreen state={mockState} {...mockHandlers} />);
    
    fireEvent.click(screen.getByText('How to Play'));
    expect(mockHandlers.onRulesClick).toHaveBeenCalledTimes(1);
  });

  it('displays loading state', () => {
    const loadingState = { ...mockState, prefetchStatus: 'loading' };
    render(<HomeScreen state={loadingState} {...mockHandlers} />);
    
    expect(screen.getByText('Loading…')).toBeInTheDocument();
  });

  it('displays transitioning state', () => {
    const transitioningState = { ...mockState, transitioning: true };
    render(<HomeScreen state={transitioningState} {...mockHandlers} />);
    
    expect(screen.getByText('Starting…')).toBeInTheDocument();
    expect(screen.getByText(/Go do what you need to/)).toBeInTheDocument();
  });

  it('displays error with retry button', () => {
    const errorState = {
      ...mockState,
      error: 'Failed to load',
      prefetchStatus: 'error',
      errorDetails: { type: 'network', retryable: true },
    };
    render(<HomeScreen state={errorState} {...mockHandlers} />);
    
    expect(screen.getByRole('alert')).toBeInTheDocument();
    expect(screen.getByText('Failed to load')).toBeInTheDocument();
    expect(screen.getByText('Try Again')).toBeInTheDocument();
  });

  it('calls onRetry when retry button clicked', () => {
    const onRetry = vi.fn();
    const errorState = {
      ...mockState,
      error: 'Failed to load',
      prefetchStatus: 'error',
      errorDetails: { type: 'network', retryable: true },
      onRetry,
    };
    render(<HomeScreen state={errorState} {...mockHandlers} />);
    
    fireEvent.click(screen.getByText('Try Again'));
    expect(onRetry).toHaveBeenCalledTimes(1);
  });

  it('disables play button when transitioning', () => {
    const transitioningState = { ...mockState, transitioning: true };
    render(<HomeScreen state={transitioningState} {...mockHandlers} />);
    
    const playButton = screen.getByRole('button', { name: 'Game starting' });
    expect(playButton).toBeDisabled();
  });

  it('disables play button when error state', () => {
    const errorState = { ...mockState, prefetchStatus: 'error' };
    render(<HomeScreen state={errorState} {...mockHandlers} />);
    
    const playButton = screen.getByRole('button', { name: 'Game unavailable' });
    expect(playButton).toBeDisabled();
  });

  it('shows offline message when not online', () => {
    const errorState = {
      ...mockState,
      error: 'Network error',
      prefetchStatus: 'error',
      errorDetails: { type: 'network', retryable: true },
    };
    render(<HomeScreen state={errorState} {...mockHandlers} isOnline={false} />);
    
    expect(screen.getByText('Offline')).toBeInTheDocument();
    expect(screen.getByText('Check your internet connection and try again.')).toBeInTheDocument();
  });

  it('renders copyright text', () => {
    render(<HomeScreen state={mockState} {...mockHandlers} />);
    
    expect(screen.getByText('©2026 Lux Spark')).toBeInTheDocument();
  });
});
