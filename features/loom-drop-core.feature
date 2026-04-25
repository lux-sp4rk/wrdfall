Feature: Loom Drop Core Gameplay
  Core game mechanics for the tile-dropping word game.
  These scenarios focus on game logic independent of UI rendering or animations.

  Background:
    Given a 5x5 grid
    And difficulty is set to normal
    And ratchet is enabled

  # ─── Grid Initialization ───

  Scenario: Grid starts with empty top rows and filled bottom rows
    When the grid is initialized
    Then rows 0-1 should be empty
    And rows 2-4 should contain letters
    And every cell should be either empty or a single letter

  Scenario: Grid fills with letters from the bag distribution
    Given letter "E" has weight 12 in the bag
    When 100 letters are drawn from the bag
    Then approximately 12% should be "E"

  Scenario: Bag is refilled when empty
    Given the bag is exhausted
    When a new letter is needed
    Then the bag should be reshuffled with all letters

  # ─── Word Selection ───

  Scenario: Valid words are detected
    Given the grid contains "C-A-T" in adjacent cells
    When cells are selected in order C-A-T
    Then the word should be recognized as valid
    And points should be calculated based on word length

  Scenario: Words must be at least 3 letters
    Given the grid contains "A-T"
    When cells are selected in order A-T
    Then the word should be marked as too short
    And no points should be awarded

  Scenario: Words must be dictionary-valid
    Given the grid contains "X-Y-Z"
    When cells are selected in order X-Y-Z
    Then the word should be marked as invalid
    And no points should be awarded

  Scenario: Selection path must be contiguous
    Given the grid has "A" at (0,0) and "T" at (4,4)
    When (0,0) and (4,4) are selected consecutively
    Then the selection should be rejected
    And message should indicate tiles must be adjacent

  # ─── Word Scoring ───

  Scenario: 3-letter words score base points
    When a 3-letter word is submitted
    Then score should increase by 3 * letter_points_sum * 1

  Scenario: 4-letter words get 2x multiplier
    When a 4-letter word is submitted
    Then multiplier should be 2

  Scenario: 5-letter words get 4x multiplier
    When a 5-letter word is submitted
    Then multiplier should be 4

  Scenario: 6+ letter words get 8x multiplier
    When a 6-letter word is submitted
    Then multiplier should be 8

  Scenario: Letter points affect word score
    Given "Q" is worth 10 points and "A" is worth 1
    When word "QA" is submitted (2 letters, so 3x minimum)
    Then base points should include Q's 10 points

  # ─── Combo Streaks ───

  Scenario: Consecutive words build combo
    Given combo streak is 0
    When a valid word is submitted
    Then combo streak should be 1
    When another valid word is submitted
    Then combo streak should be 2

  Scenario: Combo streak resets on invalid submission
    Given combo streak is 3
    When an invalid word is attempted
    Then combo streak should reset to 0

  Scenario: Combo streak provides bonus points
    Given combo streak is 2
    When a valid word is submitted worth 100 points
    Then total awarded should be 100 + (2 * combo_bonus)

  # ─── Tile Clearing ───

  Scenario: Word submission clears selected tiles
    Given grid has letters at positions (0,0), (0,1), (0,2)
    When those three cells form a word and are submitted
    Then those three cells should become empty
    And remaining tiles should not move

  # ─── Drop Mechanics ───

  Scenario: Tiles drop on timer
    Given drop interval is 10 seconds
    When 10 seconds elapse
    Then a new tile should drop in the first available column

  Scenario: Drop fills from bottom up
    Given column 0 has empty cells at rows 0-2
    When a tile drops in column 0
    Then it should occupy row 2 (lowest empty)

  Scenario: Full column prevents drops
    Given column 0 is completely filled
    When a tile attempts to drop in column 0
    Then it should try another column
    Or game over should trigger if all columns full

  Scenario: Rescue word bias drops needed letters
    Given no valid words exist in the grid
    And rescue word is "CAT" needing "C" at column 2
    When next tile drops
    Then there should be increased probability of "C" dropping in column 2

  # ─── Game Over Conditions ───

  Scenario: Game over when grid completely filled
    Given every cell in the grid is occupied
    When a drop is attempted
    Then game over should trigger

  Scenario: Game over clears the grid
    Given game over has triggered
    When game over animation completes
    Then game over modal should display final score
    And session stats should be recorded

  # ─── Freeze Power-up ───

  Scenario: Freeze pauses the drop timer
    Given freeze is not active
    When freeze is activated
    Then drop timer should be paused
    And game should be in frozen state

  Scenario: Freeze has progressive cost
    Given freeze uses is 0
    Then freeze cost should be base cost
    When freeze is used once
    Then freeze cost should increase by increment

  Scenario: Unfreeze resumes the drop timer
    Given game is frozen
    When unfreeze is triggered
    Then drop timer should resume
    And freeze cost should reset for next use

  # ─── Shake Power-up ───

  Scenario: Shake refills empty cells
    Given grid has 5 empty cells
    When shake is activated
    Then those 5 cells should be filled with random letters
    And score should decrease by shake cost

  Scenario: Shake only fills empty cells
    Given grid is completely full
    When shake is activated
    Then no change should occur to the grid
    But shake cost should still be deducted

  # ─── Swap Power-up ───

  Scenario: Swap exchanges two adjacent tiles
    Given tile "A" is at (0,0) and tile "B" is at (0,1)
    When swap mode is activated and (0,0) then (0,1) are selected
    Then tile "A" should be at (0,1) and tile "B" at (0,0)

  Scenario: Swap requires adjacent tiles
    Given tile at (0,0) and tile at (4,4)
    When swap mode attempts to exchange them
    Then swap should be rejected
    And message should indicate tiles must be adjacent

  Scenario: Swap requires both cells have letters
    Given tile at (0,0) and empty cell at (0,1)
    When swap mode attempts to exchange them
    Then swap should be rejected
    And message should indicate both tiles need letters

  Scenario: Swap can be canceled
    Given swap mode is active
    When cancel is pressed
    Then swap mode should deactivate
    And no cost should be deducted

  # ─── Draw More Power-up ───

  Scenario: Draw More adds letters to empty spaces
    Given grid has 8 empty cells
    When draw more is activated
    Then up to 5 new letters should appear in empty cells
    And score should decrease by draw more cost

  Scenario: Draw More limited by available space
    Given grid has only 2 empty cells
    When draw more is activated
    Then only 2 letters should be added

  Scenario: Draw More fails when grid is full
    Given grid is completely full
    When draw more is attempted
    Then message should indicate grid is full
    And no cost should be deducted
