import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import React from 'react';
import { TutorialPrompt } from '../TutorialPrompt.jsx';

describe('TutorialPrompt', () => {
  const mockHandlers = {
    onYes: vi.fn(),
    onNo: vi.fn(),
  };

  // TEMPORARILY DISABLED - Issue #238
  // Tutorial modal is disabled; all tests should expect null return
  // To re-enable: restore original tests from git history

  it('returns null when tutorial is disabled (issue #238)', () => {
    const { container } = render(
      <TutorialPrompt isOpen={true} {...mockHandlers} />
    );
    expect(container.firstChild).toBeNull();
  });

  it('returns null regardless of isOpen prop while disabled', () => {
    const { container: openContainer } = render(
      <TutorialPrompt isOpen={true} {...mockHandlers} />
    );
    const { container: closedContainer } = render(
      <TutorialPrompt isOpen={false} {...mockHandlers} />
    );
    expect(openContainer.firstChild).toBeNull();
    expect(closedContainer.firstChild).toBeNull();
  });

  // TODO: Restore tests below when tutorial is re-enabled
  // Original test suite covered:
  // - renders with English content by default
  // - renders with Spanish content
  // - falls back to English for unsupported language
  // - calls onYes when yes button clicked
  // - calls onNo when no button clicked
  // - applies theme class
  // - has correct aria attributes
  // See: https://github.com/lux-sp4rk/wordfall/issues/238
});
