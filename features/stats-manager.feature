Feature: Stats Manager
  The stats manager tracks player performance across sessions,
  persists data locally, and syncs with the cloud when authenticated.

  Background:
    Given stats are loaded from a fresh save file

  # ─── Session Lifecycle ───

  Scenario: Starting a new session resets per-session counters
    Given total words found is 50
    And total tiles cleared is 200
    When a new session starts
    Then session words found should be 0
    And session tiles cleared should be 0
    And total words found should still be 50

  Scenario: Ending a session accumulates to totals
    Given session words found is 12
    And session tiles cleared is 48
    And total words found is 50
    When the session ends with score 1200
    Then total words found should be 62
    And total tiles cleared should be 248

  # ─── Records ───

  Scenario: High score updates when beaten
    Given current high score is 5000
    When session ends with score 7500
    Then high score should be 7500

  Scenario: High score does not change when not beaten
    Given current high score is 5000
    When session ends with score 3000
    Then high score should still be 5000

  Scenario: Longest word updates when longer word is found
    Given current longest word is "QUARTZ"
    When word "SPARKLING" is recorded
    Then longest word should be "SPARKLING"

  Scenario: Longest word ignores case
    Given current longest word is "HELLO"
    When word "sparkling" is recorded
    Then longest word should be "sparkling"

  # ─── WPM Calculation ───

  Scenario: WPM is calculated from words and duration
    Given 15 words found in 180 seconds
    When WPM is calculated
    Then result should be 5.0

  Scenario: WPM is zero for zero duration
    Given 5 words found in 0 seconds
    When WPM is calculated
    Then result should be 0.0

  Scenario: Average WPM across sessions
    Given session history has WPMs [4.0, 6.0, 8.0]
    When average WPM is requested
    Then result should be 6.0

  Scenario: Average WPM with no sessions
    Given session history is empty
    When average WPM is requested
    Then result should be 0.0

  # ─── Session History ───

  Scenario: Session is recorded in history on end
    When session ends with score 1000 and 10 words found
    Then session history should contain a record with score 1000
    And the record should include timestamp, duration, and powerups used

  Scenario: History caps at 50 sessions
    Given session history has 50 entries
    When another session ends
    Then history should still have 50 entries
    And the oldest entry should be removed

  # ─── Power-ups ───

  Scenario: Recording power-up usage increments counter
    Given shake uses is 0
    When power-up "shake" is recorded
    Then shake uses should be 1

  Scenario: Unknown power-up types are ignored
    When power-up "nuclear_option" is recorded
    Then no error should occur

  # ─── Persistence ───

  Scenario: Save persists all stats to disk
    Given high score is 9999
    And total time played is 3600 seconds
    When stats are saved
    Then the save file should contain high score 9999
    And total time played should be 3600

  Scenario: Load restores all stats from disk
    Given a save file exists with high score 5000 and 20 sessions
    When stats are loaded
    Then high score should be 5000
    And session history should have 20 entries

  # ─── Conflict Resolution ───

  Scenario: Remote high score wins on conflict
    Given local high score is 3000
    And remote high score is 5000
    When conflicts are resolved
    Then high score should be 5000

  Scenario: Longer remote word wins on conflict
    Given local longest word is "FIRE"
    And remote longest word is "FLAME"
    When conflicts are resolved
    Then longest word should be "FLAME"

  Scenario: Conflict resolution only saves when something changes
    Given local and remote stats are identical
    When conflicts are resolved
    Then save should not be triggered
