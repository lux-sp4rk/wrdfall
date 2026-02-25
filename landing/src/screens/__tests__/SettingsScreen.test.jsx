import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { SettingsScreen } from '../SettingsScreen.jsx'

beforeEach(() => {
  localStorage.clear()
})

describe('SettingsScreen', () => {
  it('renders all three setting groups', () => {
    render(<SettingsScreen onBack={vi.fn()} onThemeChange={vi.fn()} />)
    expect(screen.getByText('Theme')).toBeTruthy()
    expect(screen.getByText('Language')).toBeTruthy()
    expect(screen.getByText('Difficulty')).toBeTruthy()
  })

  it('applies the current theme class to the container', () => {
    localStorage.setItem('word-loom-theme', 'dark')
    const { container } = render(<SettingsScreen onBack={vi.fn()} onThemeChange={vi.fn()} />)
    expect(container.firstChild.className).toContain('theme-dark')
  })

  it('calls onThemeChange and updates container class when theme is switched', () => {
    const onThemeChange = vi.fn()
    const { container } = render(<SettingsScreen onBack={vi.fn()} onThemeChange={onThemeChange} />)
    fireEvent.click(screen.getByLabelText('Dark'))
    expect(onThemeChange).toHaveBeenCalledWith('dark')
    expect(container.firstChild.className).toContain('theme-dark')
  })

  it('persists language selection to localStorage', () => {
    render(<SettingsScreen onBack={vi.fn()} onThemeChange={vi.fn()} />)
    fireEvent.click(screen.getByLabelText('Español'))
    expect(localStorage.getItem('word-loom-language')).toBe('es')
  })

  it('persists difficulty selection to localStorage', () => {
    render(<SettingsScreen onBack={vi.fn()} onThemeChange={vi.fn()} />)
    fireEvent.click(screen.getByLabelText('Hard'))
    expect(localStorage.getItem('word-loom-difficulty')).toBe('hard')
  })

  it('calls onBack when Back button is clicked', () => {
    const onBack = vi.fn()
    render(<SettingsScreen onBack={onBack} onThemeChange={vi.fn()} />)
    fireEvent.click(screen.getByText('← Back'))
    expect(onBack).toHaveBeenCalledOnce()
  })
})
