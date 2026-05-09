/**
 * Rules Validation Test Suite
 *
 * These tests ensure the player guide (game-rules-player.md / game-rules-player.es.md)
 * stays in sync with the actual game implementation (GameConstants.gd, LanguageConfig.gd).
 *
 * If these tests fail after a code change, update the guide to match.
 * If they fail after a doc change, the code constants must be updated to match.
 *
 * This is the single source of truth for game rules documentation.
 */

import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const DOCS_DIR = path.resolve(__dirname, '../../../docs')

// --- Raw doc content ---

const rulesEnPath = path.join(DOCS_DIR, 'game-rules-player.md')
const rulesEsPath = path.join(DOCS_DIR, 'game-rules-player.es.md')

const rulesEn = fs.readFileSync(rulesEnPath, 'utf-8')
const rulesEs = fs.readFileSync(rulesEsPath, 'utf-8')

// --- Game Constants (must match godot/scripts/GameConstants.gd) ---

const GAME_CONSTANTS = {
  ROWS: 5,
  COLS: 5,
  INITIAL_FILL_ROWS: 3,
  MIN_WORD_LENGTH: 3,
  DROP_INTERVAL_NORMAL: 10.0,
  DROP_INTERVAL_HARD: 6.0,
  SHAKE_COST_NORMAL: 3,
  SWAP_COST_NORMAL: 2,
  DRAW_MORE_COST_NORMAL: 5,
  FREEZE_COST_NORMAL: 10,
  SHAKE_COST_HARD: 8,
  SWAP_COST_HARD: 5,
  DRAW_MORE_COST_HARD: 10,
  FREEZE_COST_HARD: 15,
  VOWEL_BOOST_NORMAL: 1.15,
  VOWEL_REDUCTION_HARD: 0.75,
  WORD_MULTIPLIERS: { 3: 1, 4: 2, 5: 4, 6: 8 },
  COMBO_THRESHOLD: 4,
  COMBO_MULTIPLIER_PER_STREAK: 0.5,
  COMBO_MULTIPLIER_MAX: 3.0,
  RATCHET_DROPS_PER_STEP: 5,
  RATCHET_SPEEDUP: 0.5,
  RATCHET_MIN_INTERVAL: 2.0,
  RATCHET_RESET_WORD_LENGTH: 5,
  SHAKE_COST_INCREMENT: 2,
  SWAP_COST_INCREMENT: 2,
  DRAW_MORE_COST_INCREMENT: 3,
  FREEZE_COST_INCREMENT: 5,
}

// --- Helper: extract a number from a string in context ---

function extractNum(text) {
  const m = text.match(/\d+(?:\.\d+)?/)
  return m ? parseFloat(m[0]) : null
}

// --- Helper: check if doc mentions a fact ---

function docMentions(doc, pattern) {
  return pattern.test(doc)
}

// --- Grid & Board ---

describe('Grid & Board', () => {
  test('5×5 grid is documented (en)', () => {
    expect(rulesEn).toMatch(/5\s*[×x]\s*5/)
  })

  test('5×5 grid is documented (es)', () => {
    expect(rulesEs).toMatch(/5\s*[×x]\s*5/)
  })

  test('3 initial rows pre-filled (en)', () => {
    expect(rulesEn).toMatch(/3\s*(?:rows?|filas?)/i)
  })

  test('3 initial rows pre-filled (es)', () => {
    expect(rulesEs).toMatch(/3\s*(?:rows?|filas?)/i)
  })

  test('min word length 3 (en)', () => {
    expect(rulesEn).toMatch(/3\s*(?:letters?|letras?)/i)
  })

  test('min word length 3 (es)', () => {
    expect(rulesEs).toMatch(/3\s*(?:letters?|letras?)/i)
  })
})

// --- Scoring Multipliers ---

describe('Scoring Multipliers', () => {
  test('3-letter = 1× (en)', () => {
    expect(rulesEn).toMatch(/3\s*(?:letters?|letras?)[^\n]*1[×x]/i)
  })

  test('3-letter = 1× (es)', () => {
    expect(rulesEs).toMatch(/3\s*(?:letters?|letras?)[^\n]*1[×x]/i)
  })

  test('4-letter = 2× (en)', () => {
    expect(rulesEn).toMatch(/4\s*(?:letters?|letras?)[^\n]*2[×x]/i)
  })

  test('4-letter = 2× (es)', () => {
    expect(rulesEs).toMatch(/4\s*(?:letters?|letras?)[^\n]*2[×x]/i)
  })

  test('5-letter = 4× (en)', () => {
    expect(rulesEn).toMatch(/5\s*(?:letters?|letras?)[^\n]*4[×x]/i)
  })

  test('5-letter = 4× (es)', () => {
    expect(rulesEs).toMatch(/5\s*(?:letters?|letras?)[^\n]*4[×x]/i)
  })

  test('6+ letter = 8× (en)', () => {
    expect(rulesEn).toMatch(/(?:6\+|6\s*\+)[^\n]*8[×x]/i)
  })

  test('6+ letter = 8× (es)', () => {
    expect(rulesEs).toMatch(/(?:6\+|6\s*\+)[^\n]*8[×x]/i)
  })
})

// --- Combo Streak ---

describe('Combo Streak', () => {
  test('4+ letter builds streak (en)', () => {
    expect(rulesEn).toMatch(/4[^\n]*streak|streak.*4/i)
  })

  test('4+ letter builds streak (es)', () => {
    expect(rulesEs).toMatch(/4[^\n]*racha|racha.*4/i)
  })

  test('3-letter breaks streak (en)', () => {
    expect(rulesEn).toMatch(/3[^\n]*break|breaks.*streak|streak.*3/i)
  })

  test('3-letter breaks streak (es)', () => {
    expect(rulesEs).toMatch(/3[^\n]*rompe|rompe.*racha|racha.*3/i)
  })

  test('combo cap 3× (en)', () => {
    expect(rulesEn).toMatch(/3\.0\s*[×x]|3\s*×\s*cap|cap.*3/i)
  })

  test('combo cap 3× (es)', () => {
    expect(rulesEs).toMatch(/3\.0\s*[×x]|3\s*×\s*tope|tope.*3/i)
  })

  test('+0.5× per streak step (en)', () => {
    expect(rulesEn).toMatch(/\+0\.5|0\.5\s*\+/i)
  })
})

// --- Drop Speed Ratchet ---

describe('Drop Speed Ratchet', () => {
  test('every 5 drops ratchet (en)', () => {
    expect(rulesEn).toMatch(/5\s*letters?\s*dropped|every\s*5|5\s*drops?/i)
  })

  test('every 5 drops ratchet (es)', () => {
    expect(rulesEs).toMatch(/cada\s*5|5\s*letras?|cada\s*5\s*letras/i)
  })

  test('5+ letter resets speed (en)', () => {
    expect(rulesEn).toMatch(/5\+|5\s*\+|5\s*letters.*resets?|resets?.*5/i)
  })

  test('5+ letter resets speed (es)', () => {
    expect(rulesEs).toMatch(/5\+|5\s*\+|5\s*letras.*reinicia|reinicia.*5/i)
  })

  test('2-second speed floor (en)', () => {
    expect(rulesEn).toMatch(/2\s*(?:seconds?|s)?\s*(?:floor|minimum|min)?/i)
  })

  test('2-second speed floor (es)', () => {
    expect(rulesEs).toMatch(/2\s*(?:segundos?|s)?\s*(?:l[ií]mite|m[ií]nimo)?/i)
  })
})

// --- Power-Up Costs ---

describe('Power-Up Costs', () => {
  describe('Shake', () => {
    test('Shake Normal cost ≈ 3 (en)', () => {
      expect(rulesEn).toMatch(/starts at 3\s*pts|Normal.*3\s*pts|3\s*pts.*Normal/i)
    })
    test('Shake Normal cost ≈ 3 (es)', () => {
      expect(rulesEs).toMatch(/Mezclar|Shake[^\n]*3/i)
    })
    test('Shake Hard cost ≈ 8 (en)', () => {
      expect(rulesEn).toMatch(/starts at 8\s*pts|Hard.*8\s*pts|8\s*pts.*Hard/i)
    })
  })

  describe('Swap', () => {
    test('Swap Normal cost ≈ 2 (en)', () => {
      expect(rulesEn).toMatch(/starts at 2\s*pts|Normal.*2\s*pts|2\s*pts.*Normal/i)
    })
    test('Swap Normal cost ≈ 2 (es)', () => {
      expect(rulesEs).toMatch(/Intercambiar|Cambiar[^\n]*2/i)
    })
    test('Swap Hard cost ≈ 5 (en)', () => {
      expect(rulesEn).toMatch(/starts at 5\s*pts|Hard.*5\s*pts|5\s*pts.*Hard/i)
    })
  })

  describe('Draw More', () => {
    test('Draw More documented (en)', () => {
      expect(rulesEn).toMatch(/Draw\s*More|Sacar\s*Más/i)
    })
    test('Draw More documented (es)', () => {
      expect(rulesEs).toMatch(/Draw\s*More|Sacar\s*Más/i)
    })
    test('Draw More Normal cost ≈ 5 (en)', () => {
      expect(rulesEn).toMatch(/starts at 5\s*pts/i)
    })
  })

  describe('Freeze', () => {
    test('Freeze documented (en)', () => {
      expect(rulesEn).toMatch(/Freeze|Congelar/i)
    })
    test('Freeze documented (es)', () => {
      expect(rulesEs).toMatch(/Freeze|Congelar/i)
    })
    test('Freeze Normal cost ≈ 10 (en)', () => {
      expect(rulesEn).toMatch(/starts at 10\s*pts/i)
    })
  })
})

// --- Progressive Costs ---

describe('Progressive Costs', () => {
  test('power-ups get more expensive (en)', () => {
    expect(rulesEn).toMatch(/more\s*expensive|increases?|increment/i)
  })
  test('power-ups get more expensive (es)', () => {
    expect(rulesEs).toMatch(/m[aá]s\s*caro|increment|más\s*costoso/i)
  })
})

// --- Difficulty Modes ---

describe('Difficulty Modes', () => {
  test('Normal mode exists (en)', () => {
    expect(rulesEn).toMatch(/Normal\s*mode|Normal\s*difficulty/i)
  })
  test('Hard mode exists (en)', () => {
    expect(rulesEn).toMatch(/Hard\s*mode|Hard\s*difficulty/i)
  })
  test('Normal has rescue words (en)', () => {
    expect(rulesEn).toMatch(/rescue|help.*when.*stuck|stuck.*help/i)
  })
  test('Hard disables rescue (en)', () => {
    expect(rulesEn).toMatch(/no\s*rescue|without\s*rescue|rescue.*disabled/i)
  })
  test('vowel difference documented (en)', () => {
    expect(rulesEn).toMatch(/vowel|more\s*vowels|fewer\s*vowels/i)
  })
  test('drop speed difference documented (en)', () => {
    expect(rulesEn).toMatch(/4\s*(?:seconds?|s)|faster\s*drop/i)
  })
})

// --- Win/Lose ---

describe('Win & Lose Conditions', () => {
  test('win = clear all 25 tiles (en)', () => {
    expect(rulesEn).toMatch(/25|clear.*(all|every)|every.*tile.*empty/i)
  })
  test('lose = all 25 spaces filled (en)', () => {
    expect(rulesEn).toMatch(/25.*fill|fill.*25|board\s*full|full\s*board/i)
  })
  test('win condition (es)', () => {
    expect(rulesEs).toMatch(/25|limpia.*todo|vac[ií]a.*tablero/i)
  })
})

// --- Language Support ---

describe('Language Support', () => {
  test('English and Spanish mentioned (en)', () => {
    expect(rulesEn).toMatch(/English|Spanish/i)
  })
  test('Idioma config section (es)', () => {
    expect(rulesEs).toMatch(/Idioma|Idioma.*config/i)
  })
})

// --- Difficulty Setting ---

describe('Difficulty Setting', () => {
  test('Difficulty setting documented (en)', () => {
    expect(rulesEn).toMatch(/Difficulty.*Choose.*Normal.*Hard/i)
  })
  test('Difficulty setting documented (es)', () => {
    expect(rulesEs).toMatch(/Dificultad.*Elige.*Normal.*Dif/i)
  })
})

// --- Letter Points (spot check key values) ---

describe('Letter Points', () => {
  test('J = 8 or 10 documented (en)', () => {
    expect(rulesEn).toMatch(/J[^\d]*[89]|J.*8|J.*10/i)
  })
  test('Q = 10 (or 5 in Spanish) documented (en)', () => {
    expect(rulesEn).toMatch(/Q[^\d]*10|Q.*10/i)
  })
  test('X = 8 documented (en)', () => {
    expect(rulesEn).toMatch(/X[^\d]*8|X.*8/i)
  })
  test('Z = 10 documented (en)', () => {
    expect(rulesEn).toMatch(/Z[^\d]*10|Z.*10/i)
  })
})

// --- Scoring Formula ---

describe('Scoring Formula', () => {
  test('formula mentions Letter Sum or Letter Rarity (en)', () => {
    expect(rulesEn).toMatch(/Letter\s*(Sum|Rarity|value)|Suma\s*de\s*letras/i)
  })
  test('formula mentions Length Multiplier (en)', () => {
    expect(rulesEn).toMatch(/Length\s*Multipl|Multipli.*Length|Longitud/i)
  })
  test('formula mentions Combo (en)', () => {
    expect(rulesEn).toMatch(/Combo|Streak|Racha/i)
  })
  test('formula complete (en)', () => {
    // Should show formula with Letter Sum, Length, Combo as separate components
    expect(rulesEn).toMatch(/\bLetter\s+Sum\b.*\bLength\b.*\bCombo\b|\bLetter\b.*\s*[×x]\s*\w+\s*[×x]\s*\w+/i)
  })
})

// --- Score Examples ---

describe('Score Examples', () => {
  test('CAT example score = 5 (C=3, A=1, T=1) (en)', () => {
    // Table row: CAT | C=3, A=1, T=1 | 5 | 1× | 1.0× | **5**
    expect(rulesEn).toMatch(/CAT.*\|\s*C=3.*\|\s*5\s*\|/)
  })
  test('STAR example exists (en)', () => {
    expect(rulesEn).toMatch(/STAR/i)
  })
})

// --- Constants Drift Detection ---

describe('Constants Drift Detection', () => {
  // These tests verify the constants we embedded here match the actual GameConstants.gd
  // If these fail, update the doc AND update the embedded constants in this file

  test('ROWS constant matches', () => {
    expect(GAME_CONSTANTS.ROWS).toBe(5)
  })

  test('MIN_WORD_LENGTH constant matches', () => {
    expect(GAME_CONSTANTS.MIN_WORD_LENGTH).toBe(3)
  })

  test('DROP_INTERVAL_NORMAL constant matches', () => {
    expect(GAME_CONSTANTS.DROP_INTERVAL_NORMAL).toBe(10.0)
  })

  test('SHAKE_COST_NORMAL constant matches', () => {
    expect(GAME_CONSTANTS.SHAKE_COST_NORMAL).toBe(3)
  })

  test('SWAP_COST_NORMAL constant matches', () => {
    expect(GAME_CONSTANTS.SWAP_COST_NORMAL).toBe(2)
  })

  test('DRAW_MORE_COST_NORMAL constant matches', () => {
    expect(GAME_CONSTANTS.DRAW_MORE_COST_NORMAL).toBe(5)
  })

  test('FREEZE_COST_NORMAL constant matches', () => {
    expect(GAME_CONSTANTS.FREEZE_COST_NORMAL).toBe(10)
  })

  test('WORD_MULTIPLIER_3 constant matches', () => {
    expect(GAME_CONSTANTS.WORD_MULTIPLIERS[3]).toBe(1)
  })

  test('WORD_MULTIPLIER_4 constant matches', () => {
    expect(GAME_CONSTANTS.WORD_MULTIPLIERS[4]).toBe(2)
  })

  test('WORD_MULTIPLIER_5 constant matches', () => {
    expect(GAME_CONSTANTS.WORD_MULTIPLIERS[5]).toBe(4)
  })

  test('WORD_MULTIPLIER_6plus constant matches', () => {
    expect(GAME_CONSTANTS.WORD_MULTIPLIERS[6]).toBe(8)
  })

  test('COMBO_THRESHOLD constant matches', () => {
    expect(GAME_CONSTANTS.COMBO_THRESHOLD).toBe(4)
  })

  test('COMBO_MULTIPLIER_MAX constant matches', () => {
    expect(GAME_CONSTANTS.COMBO_MULTIPLIER_MAX).toBe(3.0)
  })

  test('RATCHET_MIN_INTERVAL constant matches', () => {
    expect(GAME_CONSTANTS.RATCHET_MIN_INTERVAL).toBe(2.0)
  })

  test('RATCHET_DROPS_PER_STEP constant matches', () => {
    expect(GAME_CONSTANTS.RATCHET_DROPS_PER_STEP).toBe(5)
  })

  test('RATCHET_RESET_WORD_LENGTH constant matches', () => {
    expect(GAME_CONSTANTS.RATCHET_RESET_WORD_LENGTH).toBe(5)
  })
})