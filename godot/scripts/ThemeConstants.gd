extends Node

## Theme Constants
## Central configuration for all theme colors, fonts, and styling
## Access globally via: ThemeConstants.TILE_BG_COLOR

# === Colors ===

# Background colors
const BG_GAME: Color = Color(0.17, 0.24, 0.31, 1)  # Main game background #2B3D4F

# Word tile colors
const TILE_BG_COLOR: Color = Color(0.30, 0.42, 0.54, 1)  # Lighter tile background for contrast
const TILE_BG_HOVER_COLOR: Color = Color(0.38, 0.50, 0.62, 1)  # Lighter on hover
const TILE_BG_PRESSED_COLOR: Color = Color(0.22, 0.34, 0.46, 1)  # Darker on press
const TILE_BORDER_COLOR: Color = Color(0.55, 0.65, 0.75, 1)  # Brighter border
const TILE_BORDER_WIDTH: int = 2
const TILE_CORNER_RADIUS: int = 8  # Slightly rounder
const TILE_FONT_COLOR: Color = Color.WHITE
const TILE_FONT_DISABLED_COLOR: Color = Color(1, 1, 1, 0.5)

# Tile shadow for depth
const TILE_SHADOW_COLOR: Color = Color(0, 0, 0, 0.25)
const TILE_SHADOW_SIZE: int = 3
const TILE_SHADOW_OFFSET: Vector2 = Vector2(0, 2)

# Selection highlight colors
const COLOR_SELECTED: Color = Color(0.2, 0.55, 0.95, 1)  # Brighter blue
const COLOR_SELECTED_BORDER: Color = Color(0.5, 0.75, 1.0, 1)  # Glowing border
const COLOR_TOO_SHORT: Color = Color(0.6, 0.6, 0.6, 1)  # Gray for too short

# Point label
const POINT_LABEL_COLOR: Color = Color(1, 1, 1, 0.55)

# Button colors (for action buttons)
const BUTTON_FONT_COLOR: Color = Color(0.12, 0.12, 0.15, 1)  # Dark text #1E1E26
const BUTTON_FONT_HOVER: Color = Color(0.05, 0.05, 0.08, 1)
const BUTTON_FONT_PRESSED: Color = Color.BLACK
const BUTTON_FONT_DISABLED: Color = Color(0.4, 0.4, 0.4, 1)
const BUTTON_OUTLINE_COLOR: Color = Color(1, 1, 1, 0.3)

# Modal/Dialog colors
const MODAL_BG_COLOR: Color = Color(0.22, 0.30, 0.38, 1)  # Slightly lighter than game bg
const MODAL_BORDER_COLOR: Color = Color(0.45, 0.55, 0.65, 1)
const MODAL_CORNER_RADIUS: int = 16
const MODAL_SHADOW_COLOR: Color = Color(0, 0, 0, 0.5)
const MODAL_SHADOW_SIZE: int = 16
const MODAL_SHADOW_OFFSET: Vector2 = Vector2(0, 8)

# Modal button colors
const MODAL_BUTTON_BG: Color = Color(0.35, 0.48, 0.60, 1)
const MODAL_BUTTON_BG_HOVER: Color = Color(0.42, 0.55, 0.68, 1)
const MODAL_BUTTON_BG_PRESSED: Color = Color(0.28, 0.40, 0.52, 1)
const MODAL_BUTTON_FONT_COLOR: Color = Color.WHITE

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
static func create_tile_stylebox(state: String = "normal") -> StyleBoxFlat:
	var bg_color: Color = TILE_BG_COLOR
	match state:
		"hover":
			bg_color = TILE_BG_HOVER_COLOR
		"pressed":
			bg_color = TILE_BG_PRESSED_COLOR
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = TILE_BORDER_COLOR
	style.set_border_width_all(TILE_BORDER_WIDTH)
	style.set_corner_radius_all(TILE_CORNER_RADIUS)
	
	# Add subtle shadow for depth
	style.shadow_color = TILE_SHADOW_COLOR
	style.shadow_size = TILE_SHADOW_SIZE
	style.shadow_offset = TILE_SHADOW_OFFSET
	
	return style

## Creates a StyleBoxFlat for selected tiles with glow effect
static func create_highlight_stylebox(color: Color, is_valid: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(TILE_CORNER_RADIUS)
	
	# Add glow border for valid selections
	if is_valid:
		style.border_color = COLOR_SELECTED_BORDER
		style.set_border_width_all(3)
		style.border_blend = true
	
	# Keep shadow for consistency
	style.shadow_color = TILE_SHADOW_COLOR
	style.shadow_size = TILE_SHADOW_SIZE
	style.shadow_offset = TILE_SHADOW_OFFSET
	
	return style

## Creates a StyleBoxFlat for modal/dialog panels
static func create_modal_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = MODAL_BG_COLOR
	style.border_color = MODAL_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(MODAL_CORNER_RADIUS)
	style.shadow_color = MODAL_SHADOW_COLOR
	style.shadow_size = MODAL_SHADOW_SIZE
	style.shadow_offset = MODAL_SHADOW_OFFSET
	# Add generous padding inside the panel
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 32
	style.content_margin_bottom = 32
	return style

## Creates a StyleBoxFlat for modal buttons
static func create_modal_button_stylebox(state: String = "normal") -> StyleBoxFlat:
	var bg_color: Color = MODAL_BUTTON_BG
	match state:
		"hover":
			bg_color = MODAL_BUTTON_BG_HOVER
		"pressed":
			bg_color = MODAL_BUTTON_BG_PRESSED
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(12)
	style.shadow_color = TILE_SHADOW_COLOR
	style.shadow_size = TILE_SHADOW_SIZE
	style.shadow_offset = TILE_SHADOW_OFFSET
	return style
