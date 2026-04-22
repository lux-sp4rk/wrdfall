Feature: Language Configuration
  Language config provides per-language settings including letter distribution,
  valid word lists, and UI strings. This ensures consistent game balance
  across English and Spanish modes.

  # ─── Configuration Loading ───

  Scenario: English config loads with correct code
    When English config is requested
    Then code should be "en"
    And display name should be "EN"
    And wordlist path should point to words_en.txt

  Scenario: Spanish config loads with correct code
    When Spanish config is requested
    Then code should be "es"
    And display name should be "ES"
    And wordlist path should point to words_es.txt

  Scenario: Invalid language code defaults to English
    When config for "xx" is requested
    Then English config should be returned

  # ─── Letter Distribution ───

  Scenario: English letter weights total to expected count
    Given English config is loaded
    When letter weights are summed
    Then total should be 100

  Scenario: Spanish letter weights include Ñ
    Given Spanish config is loaded
    Then extra alpha should contain codepoint 209 (Ñ)
    And letter weights should include "Ñ" with count 1

  Scenario: Spanish letter weights total to expected count
    Given Spanish config is loaded
    When letter weights are summed
    Then total should be 100

  # ─── Vowel Configuration ───

  Scenario: English has 5 vowels
    Given English config is loaded
    Then vowels should be "AEIOU"
    And target vowel ratio should be 0.38

  Scenario: Spanish has same vowel set
    Given Spanish config is loaded
    Then vowels should be "AEIOU"
    And target vowel ratio should be 0.42

  # ─── Letter Points (Scrabble-style) ───

  Scenario: Common English letters are worth 1 point
    Given English config is loaded
    Then "A" should be worth 1 point
    And "E" should be worth 1 point
    And "I" should be worth 1 point
    And "O" should be worth 1 point
    And "R" should be worth 1 point
    And "S" should be worth 1 point
    And "T" should be worth 1 point

  Scenario: Rare English letters are worth more
    Given English config is loaded
    Then "Q" should be worth 10 points
    And "Z" should be worth 10 points
    And "X" should be worth 8 points
    And "J" should be worth 8 points

  Scenario: Spanish Ñ has correct point value
    Given Spanish config is loaded
    Then "Ñ" should be worth 8 points

  # ─── Bigrams (Letter Pair Frequencies) ───

  Scenario: English Q is followed by U
    Given English config is loaded
    Then bigram for "Q" should be "UUUUU"

  Scenario: Spanish Q is also followed by U
    Given Spanish config is loaded
    Then bigram for "Q" should be "UUUUU"

  Scenario: Common English letters have varied bigrams
    Given English config is loaded
    Then bigram for "E" should contain common following letters

  # ─── Seed Words ───

  Scenario: English has at least 100 seed words
    Given English config is loaded
    Then seed words count should be >= 100

  Scenario: All English seed words are 4 letters
    Given English config is loaded
    Then every seed word should have length 4

  Scenario: Spanish has at least 80 seed words
    Given Spanish config is loaded
    Then seed words count should be >= 80

  Scenario: All Spanish seed words are 4 letters
    Given Spanish config is loaded
    Then every seed word should have length 4

  # ─── UI Strings ───

  Scenario: English UI strings include all required keys
    Given English config is loaded
    Then UI strings should contain "score"
    And UI strings should contain "game_over"
    And UI strings should contain "play_again"
    And UI strings should contain "paused"
    And UI strings should contain "shake"
    And UI strings should contain "swap"

  Scenario: Spanish UI strings are localized
    Given Spanish config is loaded
    Then "score" should be "Puntos: %d"
    And "play_again" should be "Jugar de nuevo"
    And "game_over" should contain "Fin del juego"

  Scenario: UI strings support format placeholders
    Given English config is loaded
    Then "score" should contain "%d"
    And "need_shake" should contain "%d"

  # ─── Available Languages ───

  Scenario: Available languages list includes English and Spanish
    When available languages are requested
    Then result should contain {"code": "en", "display_name": "EN"}
    And result should contain {"code": "es", "display_name": "ES"}
