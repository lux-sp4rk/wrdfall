import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';
import { RulesScreen } from '../RulesScreen.jsx';

// Mock react-markdown
vi.mock('react-markdown', () => ({
  default: ({ children }) => React.createElement('div', { 'data-testid': 'markdown' }, children),
}));

describe('RulesScreen', () => {
  const defaultProps = {
    theme: 'light',
    language: 'en',
    onBack: vi.fn(),
  };

  it('renders with English content by default', () => {
    render(<RulesScreen {...defaultProps} />);
    
    expect(screen.getByText('How to Play')).toBeInTheDocument();
    expect(screen.getByText('← Back')).toBeInTheDocument();
    expect(screen.getByTestId('markdown')).toBeInTheDocument();
  });

  it('renders with Spanish content', () => {
    render(<RulesScreen {...defaultProps} language="es" />);
    
    expect(screen.getByText('Cómo Jugar')).toBeInTheDocument();
    expect(screen.getByText('← Volver')).toBeInTheDocument();
  });

  it('falls back to English for unsupported language', () => {
    render(<RulesScreen {...defaultProps} language="fr" />);
    
    expect(screen.getByText('How to Play')).toBeInTheDocument();
  });

  it('calls onBack when back button clicked', () => {
    render(<RulesScreen {...defaultProps} />);
    
    fireEvent.click(screen.getByText('← Back'));
    expect(defaultProps.onBack).toHaveBeenCalledTimes(1);
  });

  it('applies theme class', () => {
    const { container } = render(<RulesScreen {...defaultProps} theme="dark" />);
    
    expect(container.querySelector('.theme-dark')).toBeInTheDocument();
  });
});
