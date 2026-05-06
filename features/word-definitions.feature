Feature: Word Definitions in Stats
  The stats screen shows each player's most-frequented and highest-scoring words,
  with live definitions fetched from a free dictionary API so players can learn
  what their accidental (or arcane) words actually mean.

  # ─── Data Tracking ───

  Scenario: Word frequency is tracked per session
    Given the player submits the word "QUARTZ" during gameplay
    When the session ends
    Then the word "QUARTZ" should appear in the word frequency dictionary
    And its count should be 1

  Scenario: Word frequency accumulates across sessions
    Given "QUARTZ" has been scored 3 times historically
    When the player submits "QUARTZ" again
    And the session ends
    Then the stored frequency for "QUARTZ" should be 4

  Scenario: Per-session scoring tracks total score per word
    Given the player scores "QUARTZ" 3 times in one session
    When the session ends
    Then the top-score entry for "QUARTZ" should reflect the sum of those three scores
    And the word's session-best score is preserved

  Scenario: Top-score word is the highest individual word score ever
    Given "XYLENE" was scored at 320 points in a past session
    And the current session scores "XYLENE" at 280 points
    When the session ends
    Then "XYLENE" should remain the top-score word at 320 points

  # ─── Persistence ───

  Scenario: Word frequency and top-score persist across app restarts
    Given the player has scored "OXYGEN" 7 times with a top score of 240
    When stats are saved
    Then the save file should contain "OXYGEN" in the word frequency map
    And the save file should contain "OXYGEN" in the word top-score map

  Scenario: Load restores word frequency and top-score maps
    Given a save file exists with word "HELIUM" frequency 5 and top-score 180
    When stats are loaded
    Then word_frequency["HELIUM"] should be 5
    And word_top_score["HELIUM"] should be 180

  # ─── Stats Screen Display ───

  Scenario: Stats screen shows the most-used word
    Given word "QUARTZ" has been scored 12 times
    When the stats screen is displayed
    Then there should be a "Most Played Word" row
    And it should display "QUARTZ" with use count badge "(12)"
    And it should show the definition inline

  Scenario: Stats screen shows the highest-score word
    Given word "OXYGEN" holds the highest single-word score of 380
    When the stats screen is displayed
    Then there should be a "Highest Score Word" row
    And it should display "OXYGEN" with score badge "(380 pts)"
    And it should show the definition inline

  Scenario: Word with no tracked history shows placeholder
    Given no words have been scored yet
    When the stats screen is displayed
    Then "Most Played Word" should show "—" with no definition
    And "Highest Score Word" should show "—" with no definition

  Scenario: Ties are broken by most recent occurrence
    Given "QUARTZ" and "OXYGEN" are both tied at 5 uses
    And "OXYGEN" was scored more recently
    When "Most Played Word" is determined
    Then the result should be "OXYGEN"

  # ─── Definition Fetching ───

  Scenario: Definition loads from dictionary API for a known word
    Given the player has scored "QUARTZ"
    When the stats screen shows the word row for "QUARTZ"
    Then a definition should be fetched from dictionaryapi.dev for "QUARTZ"
    And the result should be displayed inline below the word name

  Scenario: Definition fetch handles unknown words gracefully
    Given the word "XYZQW" is in the word maps but not in the dictionary
    When the definition fetch completes
    Then the word row should display "No definition found" in a muted style
    And no error should be shown to the player

  Scenario: Definition fetch handles network failure gracefully
    Given the device is offline
    When the stats screen attempts to fetch a definition
    Then the word row should show the word and count/score normally
    And definition text should be hidden or show "—" in muted style
    And no error notification should appear

  Scenario: Loading state shown while definition fetches
    Given "QUARTZ" is displayed on the stats screen
    When the definition is being fetched
    Then a subtle loading indicator should appear next to the word
    And it should resolve to the definition text or error state

  # ─── Theme & Accessibility ───

  Scenario: Word rows use theme-aware colors
    When the theme changes
    Then the word name, badge, and definition text should update to theme colors
    And the loading indicator should use the accent color

  Scenario: Definitions are tappable for read-more
    Given a word with a definition is displayed
    When the player taps the definition text
    Then a modal or bottom sheet should open with the full dictionary entry
    And it should include part of speech, pronunciation, and all definitions
