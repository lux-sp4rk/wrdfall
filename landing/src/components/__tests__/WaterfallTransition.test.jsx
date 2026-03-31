import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import React from 'react';
import { WaterfallTransition } from '../WaterfallTransition.jsx';

describe('WaterfallTransition', () => {
  it('returns null when not active', () => {
    const { container } = render(
      <WaterfallTransition isActive={false} theme="light" />
    );
    expect(container.firstChild).toBeNull();
  });

  it('renders when active', () => {
    render(<WaterfallTransition isActive={true} theme="light" />);
    
    expect(screen.getByText('Loading game...')).toBeInTheDocument();
  });

  it('renders waterfall letters', () => {
    render(<WaterfallTransition isActive={true} theme="light" />);
    
    // Check for some of the letters (use getAllByText since 'O' appears twice)
    expect(screen.getByText('W')).toBeInTheDocument();
    expect(screen.getByText('R')).toBeInTheDocument();
    expect(screen.getByText('D')).toBeInTheDocument();
    expect(screen.getByText('L')).toBeInTheDocument();
    expect(screen.getByText('M')).toBeInTheDocument();
    // 'O' appears twice, so use getAllByText
    expect(screen.getAllByText('O')).toHaveLength(2);
  });

  it('applies theme class', () => {
    const { container } = render(
      <WaterfallTransition isActive={true} theme="dark" />
    );
    
    expect(container.querySelector('.theme-dark')).toBeInTheDocument();
  });

  it('has aria-hidden attribute', () => {
    const { container } = render(
      <WaterfallTransition isActive={true} theme="light" />
    );
    
    const transition = container.querySelector('.waterfall-transition');
    expect(transition).toHaveAttribute('aria-hidden', 'true');
  });
});
