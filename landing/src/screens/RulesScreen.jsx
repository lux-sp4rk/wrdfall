import React from 'react'
import ReactMarkdown from 'react-markdown'
import rulesEn from '@docs/game-rules-player.md?raw'
import rulesEs from '@docs/game-rules-player.es.md?raw'

const UI_TEXT = {
  en: {
    back: '← Back',
    title: 'How to Play',
    tryTutorial: 'Try Interactive Tutorial',
  },
  es: {
    back: '← Volver',
    title: 'Cómo Jugar',
    tryTutorial: 'Probar Tutorial Interactivo',
  },
}

export function RulesScreen({ theme, language = 'en', onBack, onStartTutorial }) {
  const rulesContent = language === 'es' ? rulesEs : rulesEn
  const ui = UI_TEXT[language] || UI_TEXT.en

  return (
    <div className={`landing-container theme-${theme}`}>
      <div className="main-card rules-card">
        <div className="screen-header">
          <button type="button" className="back-button" onClick={onBack}>{ui.back}</button>
          <h2 className="screen-title">{ui.title}</h2>
        </div>

        <div className="rules-content">
          <ReactMarkdown
            components={{
              h1: ({ children }) => <h1 className="rules-h1">{children}</h1>,
              h2: ({ children }) => <h2 className="rules-h2">{children}</h2>,
              h3: ({ children }) => <h3 className="rules-h3">{children}</h3>,
              p: ({ children }) => <p className="rules-p">{children}</p>,
              ul: ({ children }) => <ul className="rules-ul">{children}</ul>,
              ol: ({ children }) => <ol className="rules-ol">{children}</ol>,
              li: ({ children }) => <li className="rules-li">{children}</li>,
              blockquote: ({ children }) => <blockquote className="rules-blockquote">{children}</blockquote>,
              table: ({ children }) => <table className="rules-table">{children}</table>,
              thead: ({ children }) => <thead className="rules-thead">{children}</thead>,
              tbody: ({ children }) => <tbody className="rules-tbody">{children}</tbody>,
              tr: ({ children }) => <tr className="rules-tr">{children}</tr>,
              th: ({ children }) => <th className="rules-th">{children}</th>,
              td: ({ children }) => <td className="rules-td">{children}</td>,
              strong: ({ children }) => <strong className="rules-strong">{children}</strong>,
            }}
          >
            {rulesContent}
          </ReactMarkdown>
        </div>

        {onStartTutorial && (
          <button type="button" className="primary-button" onClick={onStartTutorial}>
            {ui.tryTutorial}
          </button>
        )}
      </div>
    </div>
  )
}
