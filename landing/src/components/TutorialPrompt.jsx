import React from 'react'

const UI_TEXT = {
  en: {
    title: 'Welcome to Word Fall!',
    message: 'Would you like a quick tutorial to get started?',
    yesButton: 'Yes, show me',
    noButton: 'No, skip',
  },
  es: {
    title: '¡Bienvenido a Word Fall!',
    message: '¿Te gustaría un tutorial rápido para comenzar?',
    yesButton: 'Sí, mostrar',
    noButton: 'No, saltar',
  },
}

export function TutorialPrompt({ isOpen, onYes, onNo, language = 'en', theme = 'dark' }) {
  if (!isOpen) return null

  const ui = UI_TEXT[language] || UI_TEXT.en

  return (
    <div 
      className="tutorial-prompt-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="tutorial-title"
    >
      <div className={`tutorial-prompt-modal theme-${theme}`}>
        <h2 id="tutorial-title" className="tutorial-prompt-title">{ui.title}</h2>
        <p className="tutorial-prompt-message">{ui.message}</p>
        <div className="tutorial-prompt-buttons">
          <button 
            type="button"
            className="tutorial-prompt-yes" 
            onClick={onYes}
          >
            {ui.yesButton}
          </button>
          <button 
            type="button"
            className="tutorial-prompt-no" 
            onClick={onNo}
          >
            {ui.noButton}
          </button>
        </div>
      </div>
    </div>
  )
}
