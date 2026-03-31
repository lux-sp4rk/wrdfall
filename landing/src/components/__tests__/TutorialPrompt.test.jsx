import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';
import { TutorialPrompt } from '../TutorialPrompt.jsx';

describe('TutorialPrompt', () => {
  const mockHandlers = {
    onYes: vi.fn(),
    onNo: vi.fn(),
  };

  it('returns null when not open', () => {
    const { container } = render(
      <TutorialPrompt isOpen={false} {...mockHandlers} />
    );
    expect(container.firstChild).toBeNull();
  });

  it('renders with English content by default', () => {
    render(<TutorialPrompt isOpen={true} {...mockHandlers} />);
    
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Welcome to Wordfall!')).toBeInTheDocument();
    expect(screen.getByText('Would you like a quick tutorial to get started?')).toBeInTheDocument();
    expect(screen.getByText('Yes, show me')).toBeInTheDocument();
    expect(screen.getByText('No, skip')).toBeInTheDocument();
  });

  it('renders with Spanish content', () => {
    render(<TutorialPrompt isOpen={true} language="es" {...mockHandlers} />);
    
    expect(screen.getByText('¡Bienvenido a Wordfall!')).toBeInTheDocument();
    expect(screen.getByText('Sí, mostrar')).toBeInTheDocument();
    expect(screen.getByText('No, saltar')).toBeInTheDocument();
  });

  it('falls back to English for unsupported language', () => {
    render(<TutorialPrompt isOpen={true} language="fr" {...mockHandlers} />);
    
    expect(screen.getByText('Welcome to Wordfall!')).toBeInTheDocument();
  });

  it('calls onYes when yes button clicked', () => {
    render(<TutorialPrompt isOpen={true} {...mockHandlers} />);
    
    fireEvent.click(screen.getByText('Yes, show me'));
    expect(mockHandlers.onYes).toHaveBeenCalledTimes(1);
  });

  it('calls onNo when no button clicked', () => {
    render(<TutorialPrompt isOpen={true} {...mockHandlers} />);
    
    fireEvent.click(screen.getByText('No, skip'));
    expect(mockHandlers.onNo).toHaveBeenCalledTimes(1);
  });

  it('applies theme class', () => {
    const { container } = render(
      <TutorialPrompt isOpen={true} theme="light" {...mockHandlers} />
    );
    
    expect(container.querySelector('.theme-light')).toBeInTheDocument();
  });

  it('has correct aria attributes', () => {
    render(<TutorialPrompt isOpen={true} {...mockHandlers} />);
    
    const dialog = screen.getByRole('dialog');
    expect(dialog).toHaveAttribute('aria-modal', 'true');
    expect(dialog).toHaveAttribute('aria-labelledby', 'tutorial-title');
    
    const title = screen.getByText('Welcome to Wordfall!');
    expect(title).toHaveAttribute('id', 'tutorial-title');
  });
});
