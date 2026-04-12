extends Node

## Theme Constants
## Central configuration for all theme colors, fonts, and styling
## Access globally via: ThemeConstants.TILE_BG_COLOR

# === Colors ===

# Background colors
const BG_GAME: Color = Color(0.17, 0.24, 0.31, 1)  # Main game background #2B3D4F

# Word tile colors
const TILE_BG_COLOR: Color = Color(0.25, 0.35, 0.45, 1)  # Tile background #3F5A73
const TILE_BORDER_COLOR: Color = Color(0.4, 0.5, 0.6, 1)  # Tile border
const TILE_BORDER_WIDTH: int = 2
const TILE_CORNER_RADIUS: int = 4
const TILE_FONT_COLOR: Color = Color.WHITE
const TILE_FONT_DISABLED_COLOR: Color = Color(1, 1, 1, 0.5)

# Selection highlight colors
const COLOR_SELECTED: Color = Color(0.35, 0.65, 1.0)  # Valid word selection (blue)
const COLOR_TOO_SHORT: Color = Color(0.7, 0.7, 0.7)  # Too short word (gray)

# Point label
const POINT_LABEL_COLOR: Color = Color(1, 1, 1, 0.55)

# Button colors (for action buttons)
const BUTTON_FONT_COLOR: Color = Color(0.12, 0.12, 0.15, 1)  # Dark text #1E1E26
const BUTTON_FONT_HOVER: Color = Color(0.05, 0.05, 0.08, 1)
const BUTTON_FONT_PRESSED: Color = Color.BLACK
const BUTTON_FONT_DISABLED: Color = Color(0.4, 0.4, 0.4, 1)
const BUTTON_OUTLINE_COLOR: Color = Color(1, 1, 1, 0.3)

# === Fonts ===

const TILE_FONT_SIZE: int = 44
const POINT_LABEL_FONT_SIZE_RATIO: float = 0.4  # Relative to tile font size

# === Icons ===

const ICON_SHAKE: String = "res://assets/icons/icon_shake.svg"
const ICON_SWAP: String = "res://assets/icons/icon_swap.svg"
const ICON_DRAW_MORE: String = "res://assets/icons/icon_draw_more.svg"
const ICON_CANCEL: String = "res://assets/icons/icon_cancel.svg"

# === Helper Functions ===

## Creates a StyleBoxFlat for word tiles with standard theme colors
static func create_tile_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TILE_BG_COLOR
	style.border_color = TILE_BORDER_COLOR
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.set_corner_radius_all(TILE_CORNER_RADIUS)
	return style

## Creates a StyleBoxFlat with custom color and standard tile styling
static func create_highlight_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(TILE_CORNER_RADIUS)
	return style
