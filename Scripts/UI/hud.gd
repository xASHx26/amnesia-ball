extends CanvasLayer
## HUD — gameplay overlay (jump counter, level label, pause menu).
## Visual styles are driven by UISettingsManager (JSON-persisted).
## Inspector export ui_style applies a full preset when changed in editor.

const FIREWORKS_SCENE: PackedScene = preload("res://Scenes/Effects/fireworks.tscn")
const STYLE_LAB_SCRIPT: GDScript  = preload("res://Scripts/UI/style_lab.gd")

# ─────────────────────────────────────────────────────────────────
# Inspector preset — sets ALL UISettingsManager dimensions at once
# ─────────────────────────────────────────────────────────────────
enum UIStyle {
	MODERN_GLASS,    ## Preset 1: Frosted glass + cyan
	NEON_CYBER,      ## Preset 2: Cyberpunk dark + electric cyan
	MINIMAL_SLATE,   ## Preset 3: Slate + warm gold
	ARCADE_SYNTHWAVE ## Preset 4: Retro synthwave magenta
}

@export var ui_style: UIStyle = UIStyle.NEON_CYBER:
	set(value):
		ui_style = value
		if is_node_ready():
			_apply_preset(value)

# ─────────────────────────────────────────────────────────────────
# Node references
# ─────────────────────────────────────────────────────────────────
@onready var pause_btn:      Button        = $GameplayUI/PauseBtn
@onready var jump_label:     Label         = $GameplayUI/JumpLabel
@onready var level_label:    Label         = $GameplayUI/LevelLabel
@onready var overlay:        ColorRect     = $Overlay
@onready var pause_card:     PanelContainer = $Overlay/PauseCard
@onready var overlay_title:  Label         = $Overlay/PauseCard/VBoxContainer/TitleLabel
@onready var resume_btn:     Button        = $Overlay/PauseCard/VBoxContainer/ResumeBtn
@onready var next_level_btn: Button        = $Overlay/PauseCard/VBoxContainer/NextLevelBtn
@onready var retry_btn:      Button        = $Overlay/PauseCard/VBoxContainer/RetryBtn
@onready var main_menu_btn:  Button        = $Overlay/PauseCard/VBoxContainer/MainMenuBtn
@onready var quit_btn:       Button        = $Overlay/PauseCard/VBoxContainer/QuitBtn
@onready var style_lab_btn:  Button        = $Overlay/PauseCard/VBoxContainer/StyleLabBtn
@onready var touch_controls: Control       = $GameplayUI/ButtonPanel

var _style_lab_instance: CanvasLayer = null


# ─────────────────────────────────────────────────────────────────
# Ready
# ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	overlay.visible = false
	get_tree().paused = false

	# Pause button micro-animation setup
	await get_tree().process_frame          # ensure size is known
	pause_btn.pivot_offset = pause_btn.size / 2.0
	pause_btn.mouse_entered.connect(_on_pause_btn_hover_enter)
	pause_btn.mouse_exited.connect(_on_pause_btn_hover_exit)

	# Style Lab button setup
	_style_style_lab_btn()
	style_lab_btn.pressed.connect(_on_style_lab_pressed)

	# Listen to UISettingsManager changes
	UISettingsManager.settings_changed.connect(_on_settings_changed)

	# GameManager signals
	GameManager.jump_used.connect(_on_jump_used)
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)

	# Pause menu buttons
	pause_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	next_level_btn.pressed.connect(_on_next_level_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Apply all styles from UISettingsManager on startup
	_apply_all_styles()

	# Initial display values
	_update_jump_display(GameManager.jumps_remaining)
	_update_level_label()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				if get_tree().paused and overlay.visible and not _style_lab_instance:
					_on_resume_pressed()
				elif not get_tree().paused:
					_on_pause_pressed()


# ─────────────────────────────────────────────────────────────────
# Settings changed — re-apply everything
# ─────────────────────────────────────────────────────────────────

func _on_settings_changed() -> void:
	_apply_all_styles()


func _apply_all_styles() -> void:
	_apply_text_style()
	_apply_pause_btn_style()
	_apply_pause_menu_style()


# ─────────────────────────────────────────────────────────────────
# Preset (Inspector UIStyle export) → populates UISettingsManager
# ─────────────────────────────────────────────────────────────────

func _apply_preset(preset: UIStyle) -> void:
	match preset:
		UIStyle.MODERN_GLASS:
			UISettingsManager.text_style      = UISettingsManager.TextStyle.CLEAN_WHITE
			UISettingsManager.button_shape    = UISettingsManager.ButtonShapeStyle.GLASS_CAPSULE
			UISettingsManager.pause_btn_style = UISettingsManager.PauseButtonStyle.GLASS_CAPSULE
			UISettingsManager.panel_style     = UISettingsManager.PanelStyle.FROSTED_GLASS

		UIStyle.NEON_CYBER:
			UISettingsManager.text_style      = UISettingsManager.TextStyle.NEON_GLOW_CYAN
			UISettingsManager.button_shape    = UISettingsManager.ButtonShapeStyle.NEON_CYBER_BADGE
			UISettingsManager.pause_btn_style = UISettingsManager.PauseButtonStyle.NEON_CYBER
			UISettingsManager.panel_style     = UISettingsManager.PanelStyle.NEON_HOLOGRAM

		UIStyle.MINIMAL_SLATE:
			UISettingsManager.text_style      = UISettingsManager.TextStyle.RETRO_GOLD
			UISettingsManager.button_shape    = UISettingsManager.ButtonShapeStyle.MINIMAL_RING
			UISettingsManager.pause_btn_style = UISettingsManager.PauseButtonStyle.MINIMAL_SLATE
			UISettingsManager.panel_style     = UISettingsManager.PanelStyle.OBSIDIAN_SMOKE

		UIStyle.ARCADE_SYNTHWAVE:
			UISettingsManager.text_style      = UISettingsManager.TextStyle.MAGENTA_PULSE
			UISettingsManager.button_shape    = UISettingsManager.ButtonShapeStyle.ROYAL_AMETHYST
			UISettingsManager.pause_btn_style = UISettingsManager.PauseButtonStyle.TRANSPARENT_GLOW
			UISettingsManager.panel_style     = UISettingsManager.PanelStyle.SYNTHWAVE_VIOLET

	UISettingsManager.save_settings()
	UISettingsManager.settings_changed.emit()


# ─────────────────────────────────────────────────────────────────
# Text Style
# ─────────────────────────────────────────────────────────────────

func _apply_text_style() -> void:
	var p := UISettingsManager.get_text_style_params()
	var gameplay_labels  := [jump_label, level_label]
	var overlay_labels   := [overlay_title]
	var all_labels       := gameplay_labels + overlay_labels
	var menu_buttons     := [resume_btn, next_level_btn, retry_btn, main_menu_btn, quit_btn]

	for lbl in all_labels:
		lbl.add_theme_color_override("font_color",        p["title_color"])
		lbl.add_theme_color_override("font_shadow_color", p["shadow_color"])
		lbl.add_theme_constant_override("shadow_offset_x", p["shadow_x"])
		lbl.add_theme_constant_override("shadow_offset_y", p["shadow_y"])
		lbl.add_theme_color_override("font_outline_color",  p["outline_color"])
		lbl.add_theme_constant_override("outline_size",     p["outline_size"])

	# Button font colors (buttons show their own text)
	for btn in menu_buttons:
		btn.add_theme_color_override("font_color",       p["btn_color"])
		btn.add_theme_color_override("font_hover_color", p["btn_color"].lightened(0.2))


# ─────────────────────────────────────────────────────────────────
# Pause Button Style (⏸ in the HUD top bar)
# ─────────────────────────────────────────────────────────────────

func _apply_pause_btn_style() -> void:
	if not pause_btn:
		return

	pause_btn.flat = false
	var norm  := StyleBoxFlat.new()
	var hov   := StyleBoxFlat.new()
	var press := StyleBoxFlat.new()

	match UISettingsManager.pause_btn_style:
		UISettingsManager.PauseButtonStyle.GLASS_CAPSULE:
			norm.bg_color  = Color(0.12, 0.18, 0.28, 0.75)
			norm.set_border_width_all(1); norm.border_color = Color(1.0, 1.0, 1.0, 0.35)
			norm.set_corner_radius_all(14); norm.shadow_color = Color(0.0, 0.0, 0.0, 0.4); norm.shadow_size = 6
			hov.bg_color   = Color(0.18, 0.3, 0.45, 0.9)
			hov.set_border_width_all(1); hov.border_color = Color(0.3, 0.8, 1.0, 0.85)
			hov.set_corner_radius_all(14); hov.shadow_color = Color(0.2, 0.7, 1.0, 0.45); hov.shadow_size = 10
			press.bg_color = Color(0.1, 0.14, 0.22, 0.95); press.set_corner_radius_all(14)
			pause_btn.add_theme_color_override("font_color",       Color(0.85, 0.96, 1.0))
			pause_btn.add_theme_color_override("font_hover_color", Color(0.2, 0.9, 1.0))

		UISettingsManager.PauseButtonStyle.NEON_CYBER:
			norm.bg_color  = Color(0.04, 0.08, 0.14, 0.85)
			norm.set_border_width_all(2); norm.border_color = Color(0.0, 0.95, 1.0, 0.9)
			norm.set_corner_radius_all(6); norm.shadow_color = Color(0.0, 0.8, 1.0, 0.35); norm.shadow_size = 10
			hov.bg_color   = Color(0.08, 0.22, 0.38, 0.95)
			hov.set_border_width_all(2); hov.border_color = Color(0.4, 1.0, 1.0, 1.0)
			hov.set_corner_radius_all(6); hov.shadow_color = Color(0.0, 0.95, 1.0, 0.6); hov.shadow_size = 14
			press.bg_color = Color(0.02, 0.05, 0.1, 1.0)
			press.set_border_width_all(2); press.border_color = Color(0.0, 0.95, 1.0, 0.7); press.set_corner_radius_all(6)
			pause_btn.add_theme_color_override("font_color",       Color(0.0, 0.95, 1.0))
			pause_btn.add_theme_color_override("font_hover_color", Color(0.6, 1.0, 1.0))

		UISettingsManager.PauseButtonStyle.MINIMAL_SLATE:
			norm.bg_color  = Color(0.14, 0.16, 0.22, 0.85)
			norm.set_border_width_all(1); norm.border_color = Color(0.9, 0.78, 0.45, 0.75)
			norm.set_corner_radius_all(20); norm.shadow_color = Color(0, 0, 0, 0.5); norm.shadow_size = 8
			hov.bg_color   = Color(0.24, 0.22, 0.18, 0.95)
			hov.set_border_width_all(1); hov.border_color = Color(1.0, 0.88, 0.55, 1.0)
			hov.set_corner_radius_all(20); hov.shadow_color = Color(0.9, 0.75, 0.4, 0.4); hov.shadow_size = 12
			press.bg_color = Color(0.1, 0.11, 0.15, 0.95); press.set_corner_radius_all(20)
			pause_btn.add_theme_color_override("font_color",       Color(0.96, 0.88, 0.65))
			pause_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))

		UISettingsManager.PauseButtonStyle.TRANSPARENT_GLOW:
			norm.bg_color  = Color(1.0, 1.0, 1.0, 0.12)
			norm.set_border_width_all(1); norm.border_color = Color(1.0, 1.0, 1.0, 0.22)
			norm.set_corner_radius_all(16); norm.shadow_color = Color(1.0, 1.0, 1.0, 0.15); norm.shadow_size = 6
			hov.bg_color   = Color(0.2, 0.8, 1.0, 0.35)
			hov.set_border_width_all(1); hov.border_color = Color(0.5, 0.9, 1.0, 0.85)
			hov.set_corner_radius_all(16); hov.shadow_color = Color(0.2, 0.8, 1.0, 0.5); hov.shadow_size = 12
			press.bg_color = Color(1.0, 1.0, 1.0, 0.06); press.set_corner_radius_all(16)
			pause_btn.add_theme_color_override("font_color",       Color(1.0, 1.0, 1.0))
			pause_btn.add_theme_color_override("font_hover_color", Color(0.4, 0.95, 1.0))

		UISettingsManager.PauseButtonStyle.EMERALD_CRYSTAL:
			norm.bg_color  = Color(0.02, 0.14, 0.08, 0.85)
			norm.set_border_width_all(1.5); norm.border_color = Color(0.1, 0.95, 0.5, 0.9)
			norm.set_corner_radius_all(12); norm.shadow_color = Color(0.0, 0.9, 0.4, 0.4); norm.shadow_size = 8
			hov.bg_color   = Color(0.05, 0.25, 0.14, 0.95)
			hov.set_border_width_all(1.5); hov.border_color = Color(0.3, 1.0, 0.6, 1.0)
			hov.set_corner_radius_all(12); hov.shadow_color = Color(0.1, 1.0, 0.5, 0.65); hov.shadow_size = 12
			press.bg_color = Color(0.01, 0.08, 0.04, 0.95); press.set_corner_radius_all(12)
			pause_btn.add_theme_color_override("font_color",       Color(0.2, 1.0, 0.6))
			pause_btn.add_theme_color_override("font_hover_color", Color(0.6, 1.0, 0.8))

		UISettingsManager.PauseButtonStyle.ROYAL_AMETHYST:
			norm.bg_color  = Color(0.14, 0.06, 0.22, 0.85)
			norm.set_border_width_all(1.5); norm.border_color = Color(0.75, 0.4, 0.95, 0.8)
			norm.set_corner_radius_all(20); norm.shadow_color = Color(0.6, 0.2, 0.9, 0.4); norm.shadow_size = 8
			hov.bg_color   = Color(0.24, 0.1, 0.38, 0.95)
			hov.set_border_width_all(1.5); hov.border_color = Color(0.9, 0.55, 1.0, 1.0)
			hov.set_corner_radius_all(20); hov.shadow_color = Color(0.8, 0.3, 1.0, 0.6); hov.shadow_size = 12
			press.bg_color = Color(0.08, 0.03, 0.12, 0.95); press.set_corner_radius_all(20)
			pause_btn.add_theme_color_override("font_color",       Color(0.88, 0.7, 1.0))
			pause_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 1.0))

		UISettingsManager.PauseButtonStyle.SOLAR_FLARE:
			norm.bg_color  = Color(0.2, 0.1, 0.04, 0.85)
			norm.set_border_width_all(1.5); norm.border_color = Color(1.0, 0.55, 0.1, 0.85)
			norm.set_corner_radius_all(10); norm.shadow_color = Color(1.0, 0.4, 0.0, 0.4); norm.shadow_size = 8
			hov.bg_color   = Color(0.32, 0.16, 0.05, 0.95)
			hov.set_border_width_all(1.5); hov.border_color = Color(1.0, 0.7, 0.2, 1.0)
			hov.set_corner_radius_all(10); hov.shadow_color = Color(1.0, 0.5, 0.1, 0.65); hov.shadow_size = 12
			press.bg_color = Color(0.12, 0.05, 0.02, 0.95); press.set_corner_radius_all(10)
			pause_btn.add_theme_color_override("font_color",       Color(1.0, 0.75, 0.3))
			pause_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5))

		UISettingsManager.PauseButtonStyle.RETRO_PIXEL:
			norm.bg_color  = Color(0.08, 0.08, 0.1, 0.95)
			norm.set_border_width_all(3); norm.border_color = Color(1.0, 1.0, 1.0, 0.9)
			norm.set_corner_radius_all(2); norm.shadow_color = Color(0, 0, 0, 0.6); norm.shadow_size = 6
			hov.bg_color   = Color(0.2, 0.2, 0.28, 1.0)
			hov.set_border_width_all(3); hov.border_color = Color(1.0, 0.85, 0.2, 1.0)
			hov.set_corner_radius_all(2); hov.shadow_color = Color(1.0, 0.85, 0.2, 0.4); hov.shadow_size = 10
			press.bg_color = Color(0.02, 0.02, 0.03, 1.0)
			press.set_border_width_all(3); press.border_color = Color(0.8, 0.8, 0.8, 0.9); press.set_corner_radius_all(2)
			pause_btn.add_theme_color_override("font_color",       Color(1.0, 1.0, 1.0))
			pause_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.2))

	pause_btn.add_theme_stylebox_override("normal",  norm)
	pause_btn.add_theme_stylebox_override("hover",   hov)
	pause_btn.add_theme_stylebox_override("pressed", press)
	pause_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())


# ─────────────────────────────────────────────────────────────────
# Pause Menu Style (the overlay card + its buttons)
# ─────────────────────────────────────────────────────────────────

func _apply_pause_menu_style() -> void:
	if not pause_card or not overlay:
		return

	# Get button shape from UISettingsManager
	var shape := UISettingsManager.get_button_shape_params()
	var radius: int    = shape["radius"]
	var border: float  = shape["border"]
	var alpha_mul: float = shape["alpha_mul"]

	var panel_sb    := StyleBoxFlat.new()
	var primary_n   := StyleBoxFlat.new()
	var primary_h   := StyleBoxFlat.new()
	var secondary_n := StyleBoxFlat.new()
	var secondary_h := StyleBoxFlat.new()
	var quit_n      := StyleBoxFlat.new()
	var quit_h      := StyleBoxFlat.new()

	match UISettingsManager.panel_style:
		UISettingsManager.PanelStyle.FROSTED_GLASS:
			overlay.color = Color(0.02, 0.04, 0.08, 0.45)
			panel_sb.bg_color = Color(0.12, 0.16, 0.26, 0.45)
			panel_sb.set_border_width_all(1); panel_sb.border_color = Color(1.0, 1.0, 1.0, 0.3)
			panel_sb.set_corner_radius_all(22); panel_sb.shadow_color = Color(0,0,0,0.35); panel_sb.shadow_size = 20
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			primary_n.bg_color   = Color(0.2, 0.5, 0.8, 0.65); primary_n.border_color   = Color(1,1,1,0.3)
			primary_h.bg_color   = Color(0.25, 0.65, 0.95, 0.85)
			secondary_n.bg_color = Color(0.2, 0.25, 0.35, 0.5); secondary_n.border_color = Color(1,1,1,0.18)
			secondary_h.bg_color = Color(0.3, 0.38, 0.5, 0.75)
			quit_n.bg_color      = Color(0.7, 0.2, 0.25, 0.55)
			quit_h.bg_color      = Color(0.85, 0.25, 0.3, 0.8)

		UISettingsManager.PanelStyle.ULTRA_TRANSPARENT:
			overlay.color = Color(0.0, 0.0, 0.0, 0.22)
			panel_sb.bg_color = Color(0.05, 0.08, 0.12, 0.22)
			panel_sb.set_border_width_all(1); panel_sb.border_color = Color(0.7, 0.9, 1.0, 0.35)
			panel_sb.set_corner_radius_all(18); panel_sb.shadow_color = Color(0,0,0,0.2); panel_sb.shadow_size = 14
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
			primary_n.bg_color   = Color(0.1, 0.4, 0.7, 0.45); primary_n.border_color   = Color(0,0.85,1,0.6)
			primary_h.bg_color   = Color(0.15, 0.55, 0.9, 0.75)
			secondary_n.bg_color = Color(0.1, 0.15, 0.25, 0.35); secondary_n.border_color = Color(1,1,1,0.2)
			secondary_h.bg_color = Color(0.2, 0.28, 0.4, 0.6)
			quit_n.bg_color      = Color(0.5, 0.1, 0.18, 0.45); quit_n.border_color = Color(1,0.3,0.3,0.5)
			quit_h.bg_color      = Color(0.7, 0.15, 0.25, 0.7)

		UISettingsManager.PanelStyle.NEON_HOLOGRAM:
			overlay.color = Color(0.01, 0.03, 0.06, 0.4)
			panel_sb.bg_color = Color(0.02, 0.1, 0.16, 0.38)
			panel_sb.set_border_width_all(2); panel_sb.border_color = Color(0.0, 0.95, 1.0, 0.85)
			panel_sb.set_corner_radius_all(14); panel_sb.shadow_color = Color(0,0.8,1,0.4); panel_sb.shadow_size = 24
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(0.2, 1.0, 1.0))
			primary_n.bg_color   = Color(0.04, 0.35, 0.55, 0.55); primary_n.border_color = Color(0,0.95,1,0.9)
			primary_h.bg_color   = Color(0.08, 0.5, 0.75, 0.85)
			secondary_n.bg_color = Color(0.15, 0.08, 0.25, 0.45); secondary_n.border_color = Color(0.85,0.3,1,0.7)
			secondary_h.bg_color = Color(0.28, 0.15, 0.42, 0.75)
			quit_n.bg_color      = Color(0.45, 0.05, 0.18, 0.55); quit_n.border_color = Color(1,0.2,0.4,0.8)
			quit_h.bg_color      = Color(0.65, 0.1, 0.28, 0.85)

		UISettingsManager.PanelStyle.OBSIDIAN_SMOKE:
			overlay.color = Color(0.01, 0.01, 0.02, 0.5)
			panel_sb.bg_color = Color(0.08, 0.09, 0.12, 0.55)
			panel_sb.set_border_width_all(1); panel_sb.border_color = Color(0.88, 0.75, 0.45, 0.5)
			panel_sb.set_corner_radius_all(20); panel_sb.shadow_color = Color(0,0,0,0.45); panel_sb.shadow_size = 18
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))
			primary_n.bg_color   = Color(0.75, 0.6, 0.25, 0.65); primary_n.border_color = Color(0.95,0.82,0.45,0.7)
			primary_h.bg_color   = Color(0.9, 0.72, 0.3, 0.85)
			secondary_n.bg_color = Color(0.18, 0.18, 0.22, 0.5); secondary_n.border_color = Color(0.85,0.7,0.4,0.3)
			secondary_h.bg_color = Color(0.28, 0.28, 0.34, 0.75)
			quit_n.bg_color      = Color(0.35, 0.14, 0.16, 0.55); quit_n.border_color = Color(0.7,0.3,0.3,0.5)
			quit_h.bg_color      = Color(0.5, 0.2, 0.22, 0.8)

		UISettingsManager.PanelStyle.SYNTHWAVE_VIOLET:
			overlay.color = Color(0.08, 0.02, 0.12, 0.35)
			panel_sb.bg_color = Color(0.16, 0.05, 0.24, 0.42)
			panel_sb.set_border_width_all(2.5); panel_sb.border_color = Color(1.0, 0.2, 0.7, 0.8)
			panel_sb.set_corner_radius_all(12); panel_sb.shadow_color = Color(1,0.1,0.6,0.35); panel_sb.shadow_size = 24
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.75))
			primary_n.bg_color   = Color(0.8, 0.12, 0.5, 0.6); primary_n.border_color = Color(1,0.3,0.75,0.8)
			primary_h.bg_color   = Color(0.95, 0.2, 0.6, 0.85)
			secondary_n.bg_color = Color(0.05, 0.32, 0.42, 0.5); secondary_n.border_color = Color(0.2,0.9,0.8,0.7)
			secondary_h.bg_color = Color(0.1, 0.48, 0.6, 0.75)
			quit_n.bg_color      = Color(0.45, 0.08, 0.25, 0.55); quit_n.border_color = Color(1,0.2,0.4,0.7)
			quit_h.bg_color      = Color(0.65, 0.12, 0.35, 0.8)

		UISettingsManager.PanelStyle.EMERALD_MATRIX:
			overlay.color = Color(0.01, 0.04, 0.02, 0.4)
			panel_sb.bg_color = Color(0.03, 0.12, 0.07, 0.38)
			panel_sb.set_border_width_all(2); panel_sb.border_color = Color(0.1, 0.95, 0.5, 0.85)
			panel_sb.set_corner_radius_all(16); panel_sb.shadow_color = Color(0,0.9,0.4,0.35); panel_sb.shadow_size = 22
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.6))
			primary_n.bg_color   = Color(0.05, 0.4, 0.2, 0.6); primary_n.border_color = Color(0.2,1,0.6,0.8)
			primary_h.bg_color   = Color(0.1, 0.55, 0.28, 0.85)
			secondary_n.bg_color = Color(0.05, 0.18, 0.1, 0.45); secondary_n.border_color = Color(0.1,0.8,0.4,0.5)
			secondary_h.bg_color = Color(0.1, 0.28, 0.16, 0.75)
			quit_n.bg_color      = Color(0.4, 0.1, 0.15, 0.55); quit_n.border_color = Color(0.9,0.2,0.3,0.7)
			quit_h.bg_color      = Color(0.6, 0.15, 0.2, 0.8)

		UISettingsManager.PanelStyle.AURORA_BOREALIS:
			overlay.color = Color(0.02, 0.04, 0.08, 0.35)
			panel_sb.bg_color = Color(0.06, 0.14, 0.22, 0.38)
			panel_sb.set_border_width_all(2); panel_sb.border_color = Color(0.3, 0.9, 0.95, 0.85)
			panel_sb.set_corner_radius_all(24); panel_sb.shadow_color = Color(0.2,0.5,0.9,0.35); panel_sb.shadow_size = 24
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
			primary_n.bg_color   = Color(0.1, 0.45, 0.7, 0.6); primary_n.border_color = Color(0.4,0.95,1,0.8)
			primary_h.bg_color   = Color(0.15, 0.6, 0.85, 0.85)
			secondary_n.bg_color = Color(0.15, 0.12, 0.32, 0.5); secondary_n.border_color = Color(0.7,0.4,0.95,0.6)
			secondary_h.bg_color = Color(0.25, 0.2, 0.48, 0.75)
			quit_n.bg_color      = Color(0.55, 0.1, 0.25, 0.55); quit_n.border_color = Color(1,0.3,0.5,0.7)
			quit_h.bg_color      = Color(0.75, 0.15, 0.35, 0.8)

		UISettingsManager.PanelStyle.MIDNIGHT_ROSE:
			overlay.color = Color(0.06, 0.01, 0.03, 0.45)
			panel_sb.bg_color = Color(0.16, 0.05, 0.08, 0.42)
			panel_sb.set_border_width_all(1.5); panel_sb.border_color = Color(0.95, 0.45, 0.55, 0.75)
			panel_sb.set_corner_radius_all(20); panel_sb.shadow_color = Color(0.8,0.15,0.3,0.35); panel_sb.shadow_size = 20
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.7))
			primary_n.bg_color   = Color(0.7, 0.2, 0.32, 0.6); primary_n.border_color = Color(1,0.5,0.65,0.8)
			primary_h.bg_color   = Color(0.85, 0.28, 0.42, 0.85)
			secondary_n.bg_color = Color(0.22, 0.1, 0.14, 0.5); secondary_n.border_color = Color(0.85,0.4,0.5,0.4)
			secondary_h.bg_color = Color(0.32, 0.16, 0.22, 0.75)
			quit_n.bg_color      = Color(0.45, 0.05, 0.1, 0.6); quit_n.border_color = Color(0.9,0.15,0.2,0.7)
			quit_h.bg_color      = Color(0.65, 0.1, 0.15, 0.85)

		UISettingsManager.PanelStyle.SUNSET_HORIZON:
			overlay.color = Color(0.08, 0.03, 0.02, 0.35)
			panel_sb.bg_color = Color(0.18, 0.08, 0.04, 0.42)
			panel_sb.set_border_width_all(2); panel_sb.border_color = Color(1.0, 0.55, 0.2, 0.8)
			panel_sb.set_corner_radius_all(18); panel_sb.shadow_color = Color(1,0.4,0.1,0.35); panel_sb.shadow_size = 22
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.35))
			primary_n.bg_color   = Color(0.85, 0.35, 0.15, 0.65); primary_n.border_color = Color(1,0.65,0.3,0.85)
			primary_h.bg_color   = Color(0.98, 0.45, 0.2, 0.85)
			secondary_n.bg_color = Color(0.25, 0.12, 0.08, 0.5); secondary_n.border_color = Color(0.9,0.5,0.25,0.4)
			secondary_h.bg_color = Color(0.38, 0.18, 0.12, 0.75)
			quit_n.bg_color      = Color(0.5, 0.1, 0.12, 0.6); quit_n.border_color = Color(0.95,0.25,0.25,0.7)
			quit_h.bg_color      = Color(0.7, 0.15, 0.18, 0.8)

		UISettingsManager.PanelStyle.DEEP_ABYSS:
			overlay.color = Color(0.01, 0.02, 0.05, 0.3)
			panel_sb.bg_color = Color(0.03, 0.06, 0.12, 0.28)
			panel_sb.set_border_width_all(1.5); panel_sb.border_color = Color(0.15, 0.5, 0.95, 0.8)
			panel_sb.set_corner_radius_all(24); panel_sb.shadow_color = Color(0,0.3,0.9,0.4); panel_sb.shadow_size = 26
			panel_sb.set_content_margin_all(20)
			overlay_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
			primary_n.bg_color   = Color(0.08, 0.35, 0.75, 0.55); primary_n.border_color = Color(0.2,0.7,1,0.85)
			primary_h.bg_color   = Color(0.12, 0.48, 0.9, 0.8)
			secondary_n.bg_color = Color(0.05, 0.12, 0.22, 0.4); secondary_n.border_color = Color(0.15,0.45,0.8,0.5)
			secondary_h.bg_color = Color(0.08, 0.2, 0.35, 0.7)
			quit_n.bg_color      = Color(0.4, 0.08, 0.18, 0.5); quit_n.border_color = Color(0.8,0.2,0.35,0.7)
			quit_h.bg_color      = Color(0.6, 0.12, 0.25, 0.75)

	# Apply button shape (corner radius + border + alpha) to all button styles
	var style_boxes: Array[StyleBoxFlat] = [primary_n, primary_h, secondary_n, secondary_h, quit_n, quit_h]
	for sb in style_boxes:
		sb.set_corner_radius_all(radius)
		if border > 0.0 and sb.border_color == Color(0,0,0,0):
			sb.border_color = sb.bg_color.lightened(0.3)
		sb.set_border_width_all(border)
		var c: Color = sb.bg_color
		sb.bg_color = Color(c.r, c.g, c.b, c.a * alpha_mul)


	# Style Lab button styling (subtle, dimmed)
	_style_style_lab_btn()

	pause_card.add_theme_stylebox_override("panel", panel_sb)

	for b in [resume_btn, next_level_btn]:
		b.add_theme_stylebox_override("normal",  primary_n)
		b.add_theme_stylebox_override("hover",   primary_h)
		b.add_theme_stylebox_override("pressed", primary_h)
		b.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	for b in [retry_btn, main_menu_btn]:
		b.add_theme_stylebox_override("normal",  secondary_n)
		b.add_theme_stylebox_override("hover",   secondary_h)
		b.add_theme_stylebox_override("pressed", secondary_h)
		b.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	quit_btn.add_theme_stylebox_override("normal",  quit_n)
	quit_btn.add_theme_stylebox_override("hover",   quit_h)
	quit_btn.add_theme_stylebox_override("pressed", quit_h)
	quit_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())


func _style_style_lab_btn() -> void:
	if not style_lab_btn:
		return
	var lab_n := StyleBoxFlat.new()
	lab_n.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	lab_n.set_border_width_all(1)
	lab_n.border_color = Color(1.0, 1.0, 1.0, 0.18)
	lab_n.set_corner_radius_all(8)
	var lab_h := StyleBoxFlat.new()
	lab_h.bg_color = Color(0.0, 0.8, 1.0, 0.18)
	lab_h.set_border_width_all(1)
	lab_h.border_color = Color(0.0, 0.9, 1.0, 0.6)
	lab_h.set_corner_radius_all(8)
	style_lab_btn.add_theme_stylebox_override("normal",  lab_n)
	style_lab_btn.add_theme_stylebox_override("hover",   lab_h)
	style_lab_btn.add_theme_stylebox_override("pressed", lab_h)
	style_lab_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	style_lab_btn.add_theme_color_override("font_color",       Color(0.8, 0.9, 1.0, 0.7))
	style_lab_btn.add_theme_color_override("font_hover_color", Color(0.0, 0.95, 1.0))


# ─────────────────────────────────────────────────────────────────
# Pause button hover micro-animation
# ─────────────────────────────────────────────────────────────────

func _on_pause_btn_hover_enter() -> void:
	var anim_params := UISettingsManager.get_animation_params()
	var h_scale: Vector2 = anim_params["hover_scale"]
	var dur: float = max(float(anim_params["duration"]) * 0.5, 0.05)
	var trans: int = anim_params["trans_type"]
	var eas: int   = anim_params["ease_type"]
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(pause_btn, "scale", h_scale, dur).set_trans(trans).set_ease(eas)


func _on_pause_btn_hover_exit() -> void:
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(pause_btn, "scale", Vector2.ONE, 0.1)


# ─────────────────────────────────────────────────────────────────
# Style Lab
# ─────────────────────────────────────────────────────────────────

func _on_style_lab_pressed() -> void:
	if _style_lab_instance:
		return
	_style_lab_instance = STYLE_LAB_SCRIPT.new()
	_style_lab_instance.closed.connect(_on_style_lab_closed)
	add_child(_style_lab_instance)


func _on_style_lab_closed() -> void:
	_style_lab_instance = null


# ─────────────────────────────────────────────────────────────────
# HUD updates
# ─────────────────────────────────────────────────────────────────

func _update_level_label() -> void:
	level_label.text = "S%d • L%d" % [GameManager.get_stage(), GameManager.get_level_in_stage()]


func _update_jump_display(remaining: int) -> void:
	if remaining >= GameManager.MAX_JUMP_CAP:
		jump_label.text = "Jumps: %d (MAX)" % remaining
	else:
		jump_label.text = "Jumps: %d" % remaining

	if remaining <= 1 and remaining > 0:
		jump_label.modulate = Color(1.0, 0.3, 0.2)
		var tw := create_tween()
		tw.tween_property(jump_label, "scale", Vector2(1.3, 1.3), 0.1)
		tw.tween_property(jump_label, "scale", Vector2.ONE, 0.15)
	elif remaining == 0:
		jump_label.modulate = Color(1.0, 0.15, 0.1)
	else:
		jump_label.modulate = Color.WHITE


# ─────────────────────────────────────────────────────────────────
# Signal handlers (GameManager)
# ─────────────────────────────────────────────────────────────────

func _on_jump_used(remaining: int) -> void:
	_update_jump_display(remaining)


func _on_level_started(remaining: int) -> void:
	get_tree().paused = false
	overlay.visible = false
	touch_controls.visible = true
	_update_jump_display(remaining)
	_update_level_label()


func _on_level_completed(level_num: int) -> void:
	var fw := FIREWORKS_SCENE.instantiate()
	fw.position = Vector2(240, 400)
	add_child(fw)
	var stage     := GameManager.get_stage(level_num)
	var lvl_stage := GameManager.get_level_in_stage(level_num)
	await get_tree().create_timer(0.5).timeout
	_show_overlay("Stage %d - Level %d Complete!" % [stage, lvl_stage], false, true, false, true, false)


func _on_game_over() -> void:
	_show_overlay("Game Over!", false, false, true, true, false)


# ─────────────────────────────────────────────────────────────────
# Pause / Resume
# ─────────────────────────────────────────────────────────────────

func _on_pause_pressed() -> void:
	get_tree().paused = true
	_show_overlay("Paused", true, false, false, true, true)


func _on_resume_pressed() -> void:
	get_tree().paused = false
	overlay.visible = false
	touch_controls.visible = true


func _show_overlay(title: String, show_resume: bool, show_next: bool,
		show_retry: bool, show_main_menu: bool, show_quit: bool) -> void:
	overlay_title.text = title
	resume_btn.visible     = show_resume
	next_level_btn.visible = show_next
	retry_btn.visible      = show_retry
	main_menu_btn.visible  = show_main_menu
	quit_btn.visible       = show_quit
	style_lab_btn.visible  = show_resume  # only show Style Lab in Pause mode
	touch_controls.visible = false

	var anim_params := UISettingsManager.get_animation_params()
	var dur: float = anim_params["duration"]
	var trans: int = anim_params["trans_type"]
	var eas: int   = anim_params["ease_type"]
	var init_scale: Vector2 = anim_params["initial_scale"]

	overlay.visible = true
	overlay.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(overlay, "modulate:a", 1.0, dur)

	overlay_title.scale = init_scale
	overlay_title.pivot_offset = overlay_title.size / 2
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(overlay_title, "scale", Vector2.ONE, dur).set_trans(trans).set_ease(eas)



# ─────────────────────────────────────────────────────────────────
# Button handlers
# ─────────────────────────────────────────────────────────────────

func _on_next_level_pressed() -> void:
	get_tree().paused = false
	GameManager.next_level()


func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_level()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to_main_menu()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
