extends Control
## Main Menu — customizable background shaders, layout, button styles, title themes,
## and ball animations. Inspector @exports work in parallel with UISettingsManager.
## Options button opens the Style Lab for full live customization.

const STYLE_LAB_SCRIPT: GDScript = preload("res://Scripts/UI/style_lab.gd")

# ─────────────────────────────────────────────────────────────────
# Inspector enums (parallel — these still work in the Godot editor)
# ─────────────────────────────────────────────────────────────────
enum BounceStyle {
	TWEEN_PROCEDURAL,
	ANIMATION_PLAYER_CLASSIC,
	ANIMATION_PLAYER_HIGH_JUMP,
	ANIMATION_PLAYER_DOUBLE_HOP
}

enum ShaderStyle {
	GRID_WAVE,
	CYBER_HEXAGONS,
	NEON_ORBS,
	CRT_SCANLINES,  ## NEW — CRT phosphor scanlines
	STAR_WARP       ## NEW — Radial star tunnel
}

enum LayoutStyle {
	CENTER_STACK,
	LEFT_ALIGNED,
	BOTTOM_PANEL,
	TOP_BAR         ## NEW — horizontal top bar
}

enum ButtonStyle {
	DARK_GLASS,
	SOLID_NEON,
	ROUNDED_PILL,
	CRYSTAL_BORDER  ## NEW — outline-only border style
}

enum TitleStyle {
	NEON_CYAN,
	GOLD_RETRO,
	MAGENTA_PULSE,
	GHOST_SLATE,    ## NEW — muted stone-white
	EMERALD_BRIGHT  ## NEW — vivid green
}

# ─────────────────────────────────────────────────────────────────
# Exports
# ─────────────────────────────────────────────────────────────────
@export_group("Menu Customization Options")
@export var bounce_style: BounceStyle = BounceStyle.ANIMATION_PLAYER_CLASSIC
@export var shader_style: ShaderStyle = ShaderStyle.GRID_WAVE
@export var layout_style: LayoutStyle = LayoutStyle.CENTER_STACK
@export var button_style: ButtonStyle = ButtonStyle.DARK_GLASS
@export var title_style:  TitleStyle  = TitleStyle.NEON_CYAN

# ─────────────────────────────────────────────────────────────────
# Node references
# ─────────────────────────────────────────────────────────────────
@onready var bg_rect:           ColorRect      = $BackgroundRect
@onready var title_container:   VBoxContainer  = $TitleContainer
@onready var title_label:       Label          = $TitleContainer/TitleLabel
@onready var subtitle_label:    Label          = $TitleContainer/SubTitleLabel
@onready var button_container:  VBoxContainer  = %ButtonContainer
@onready var start_btn:         Button         = %StartBtn
@onready var level_select_btn:  Button         = %LevelSelectBtn
@onready var options_btn:       Button         = %OptionsBtn
@onready var credits_btn:       Button         = %CreditsBtn
@onready var google_play_btn:   TextureButton  = %GooglePlayBtn
@onready var wip_modal:         ColorRect      = $WipModal
@onready var wip_title:         Label          = %WipTitle
@onready var wip_msg:           Label          = %WipMsg
@onready var wip_close_btn:     Button         = %WipCloseBtn
@onready var anim_ball:         MeshInstance2D = %AnimBall
@onready var anim_platform:     MeshInstance2D = %AnimPlatform
@onready var anim_player:       AnimationPlayer = $AnimationPlayer

# Preloaded shaders
const SHADER_GRID  = preload("res://Shaders/background_grid.gdshader")
const SHADER_HEX   = preload("res://Shaders/background_hexagons.gdshader")
const SHADER_ORBS  = preload("res://Shaders/background_orbs.gdshader")
const SHADER_SCAN  = preload("res://Shaders/background_scanlines.gdshader")
const SHADER_WARP  = preload("res://Shaders/background_starwarp.gdshader")

var ball_base_y: float    = 580.0
var ball_jump_height: float = 140.0
var _style_lab_instance: CanvasLayer = null


# ─────────────────────────────────────────────────────────────────
# Ready
# ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	wip_modal.visible = false

	start_btn.pressed.connect(_on_start_pressed)
	level_select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/UI/level_selector.tscn"))
	options_btn.pressed.connect(_on_options_pressed)
	credits_btn.pressed.connect(func(): _show_wip("Credits", "Amnesia Ball\nDeveloped with Godot Engine 4"))
	google_play_btn.pressed.connect(func(): _show_wip("Google Play Games", "Google Play achievements & leaderboards coming soon!"))
	wip_close_btn.pressed.connect(_hide_wip)

	# Connect button hover micro-animations
	for btn in [start_btn, level_select_btn, options_btn, credits_btn]:
		btn.mouse_entered.connect(func(): _on_btn_hover(btn, true))
		btn.mouse_exited.connect(func(): _on_btn_hover(btn, false))


	# Listen to UISettingsManager
	UISettingsManager.settings_changed.connect(_on_settings_changed)

	# Apply inspector exports first, then UISettingsManager overrides on top
	_apply_all_customizations()
	_apply_ui_manager_styles()


# ─────────────────────────────────────────────────────────────────
# UISettingsManager → re-apply on change
# ─────────────────────────────────────────────────────────────────

func _on_settings_changed() -> void:
	_apply_ui_manager_styles()


## Applies all styles driven by UISettingsManager (overrides inspector in runtime).
func _apply_ui_manager_styles() -> void:
	_apply_text_style_from_manager()
	_apply_button_shape_from_manager()
	_apply_layout_from_manager()
	_apply_shader_from_manager()
	_apply_bounce_from_manager()


# ─────────────────────────────────────────────────────────────────
# Inspector-driven customizations (still work in editor)
# ─────────────────────────────────────────────────────────────────

func _apply_all_customizations() -> void:
	_setup_bounce_animation()
	_apply_shader_style()
	_apply_layout_style()
	_apply_button_style()
	_apply_title_style()


## 1. Background Shader (inspector)
func _apply_shader_style() -> void:
	var mat := ShaderMaterial.new()
	match shader_style:
		ShaderStyle.GRID_WAVE:       mat.shader = SHADER_GRID
		ShaderStyle.CYBER_HEXAGONS:  mat.shader = SHADER_HEX
		ShaderStyle.NEON_ORBS:       mat.shader = SHADER_ORBS
		ShaderStyle.CRT_SCANLINES:   mat.shader = SHADER_SCAN
		ShaderStyle.STAR_WARP:       mat.shader = SHADER_WARP
	bg_rect.material = mat


## 2. Layout (inspector)
func _apply_layout_style() -> void:
	_set_layout(layout_style)


## 3. Button visual style/color (inspector)
func _apply_button_style() -> void:
	var buttons := [start_btn, level_select_btn, options_btn, credits_btn]
	for btn in buttons:
		var style_n := StyleBoxFlat.new()
		var style_h := StyleBoxFlat.new()
		match button_style:
			ButtonStyle.DARK_GLASS:
				style_n.bg_color = Color(0.08, 0.12, 0.22, 0.65)
				style_n.border_color = Color(0.0, 0.8, 1.0, 0.5); style_n.set_border_width_all(2); style_n.set_corner_radius_all(8)
				style_h.bg_color = Color(0.12, 0.2, 0.35, 0.85)
				style_h.border_color = Color(0.0, 0.95, 1.0, 0.9); style_h.set_border_width_all(2); style_h.set_corner_radius_all(8)
				btn.add_theme_color_override("font_color", Color.WHITE)
			ButtonStyle.SOLID_NEON:
				style_n.bg_color = Color(0.0, 0.65, 0.85, 0.9); style_n.set_corner_radius_all(6)
				style_h.bg_color = Color(0.1, 0.8, 1.0, 1.0); style_h.set_corner_radius_all(6)
				btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.15))
			ButtonStyle.ROUNDED_PILL:
				style_n.bg_color = Color(0.25, 0.12, 0.45, 0.8)
				style_n.border_color = Color(1.0, 0.2, 0.7, 0.7); style_n.set_border_width_all(2); style_n.set_corner_radius_all(24)
				style_h.bg_color = Color(0.35, 0.18, 0.6, 0.95)
				style_h.border_color = Color(1.0, 0.4, 0.8, 1.0); style_h.set_border_width_all(2); style_h.set_corner_radius_all(24)
				btn.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))
			ButtonStyle.CRYSTAL_BORDER:
				style_n.bg_color = Color(1.0, 1.0, 1.0, 0.04)
				style_n.border_color = Color(0.7, 0.9, 1.0, 0.85); style_n.set_border_width_all(1.5); style_n.set_corner_radius_all(14)
				style_h.bg_color = Color(0.1, 0.4, 0.75, 0.15)
				style_h.border_color = Color(0.4, 0.85, 1.0, 1.0); style_h.set_border_width_all(1.5); style_h.set_corner_radius_all(14)
				btn.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
		var style_pressed := style_h.duplicate() as StyleBoxFlat
		style_pressed.bg_color = style_pressed.bg_color.darkened(0.2)
		btn.add_theme_stylebox_override("normal",  style_n)
		btn.add_theme_stylebox_override("hover",   style_h)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())


## 4. Title style/color (inspector)
func _apply_title_style() -> void:
	match title_style:
		TitleStyle.NEON_CYAN:
			title_label.add_theme_color_override("font_color", Color.WHITE)
			title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.8, 1.0, 0.6))
			subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.85))
		TitleStyle.GOLD_RETRO:
			title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			title_label.add_theme_color_override("font_shadow_color", Color(0.85, 0.35, 0.0, 0.8))
			subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 0.9))
		TitleStyle.MAGENTA_PULSE:
			title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 1.0, 1.0))
			title_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.1, 0.65, 0.75))
			subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.85, 0.85))
		TitleStyle.GHOST_SLATE:
			title_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.85, 1.0))
			title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
			subtitle_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 0.85))
		TitleStyle.EMERALD_BRIGHT:
			title_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.65, 1.0))
			title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.8, 0.35, 0.7))
			subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.65, 0.85))


## 5. Bounce animation (inspector)
func _setup_bounce_animation() -> void:
	match bounce_style:
		BounceStyle.TWEEN_PROCEDURAL:
			if anim_player and anim_player.is_playing():
				anim_player.stop()
			if anim_ball:
				ball_base_y = anim_ball.position.y
				_start_ball_bounce_loop()
		BounceStyle.ANIMATION_PLAYER_CLASSIC:
			if anim_player:
				anim_player.play("classic_bounce")
		BounceStyle.ANIMATION_PLAYER_HIGH_JUMP:
			if anim_player:
				anim_player.play("high_jump_spin")
		BounceStyle.ANIMATION_PLAYER_DOUBLE_HOP:
			if anim_player:
				anim_player.play("double_hop")


# ─────────────────────────────────────────────────────────────────
# UISettingsManager-driven overrides
# ─────────────────────────────────────────────────────────────────

## Override: text style on titles
func _apply_text_style_from_manager() -> void:
	var p := UISettingsManager.get_text_style_params()
	title_label.add_theme_color_override("font_color",        p["title_color"])
	title_label.add_theme_color_override("font_shadow_color", p["shadow_color"])
	title_label.add_theme_constant_override("shadow_offset_x", p["shadow_x"])
	title_label.add_theme_constant_override("shadow_offset_y", p["shadow_y"])
	title_label.add_theme_color_override("font_outline_color",  p["outline_color"])
	title_label.add_theme_constant_override("outline_size",     p["outline_size"])
	subtitle_label.add_theme_color_override("font_color", p["btn_color"])
	var buttons := [start_btn, level_select_btn, options_btn, credits_btn]
	for btn in buttons:
		btn.add_theme_color_override("font_color",       p["btn_color"])
		btn.add_theme_color_override("font_hover_color", p["btn_color"].lightened(0.18))


## Override: button shape from UISettingsManager (modifies corner-radius on top of color)
func _apply_button_shape_from_manager() -> void:
	var shape := UISettingsManager.get_button_shape_params()
	var radius: int = shape["radius"]
	var border: float = shape["border"]
	var alpha_mul: float = shape["alpha_mul"]
	var buttons := [start_btn, level_select_btn, options_btn, credits_btn]
	for btn in buttons:
		var snorm := btn.get_theme_stylebox("normal") as StyleBoxFlat
		var shov  := btn.get_theme_stylebox("hover")  as StyleBoxFlat
		var spres := btn.get_theme_stylebox("pressed") as StyleBoxFlat
		var style_boxes: Array[StyleBoxFlat] = []
		if snorm: style_boxes.append(snorm)
		if shov: style_boxes.append(shov)
		if spres: style_boxes.append(spres)
		for sb in style_boxes:
			sb.set_corner_radius_all(radius)
			sb.set_border_width_all(border)
			var c: Color = sb.bg_color
			sb.bg_color = Color(c.r, c.g, c.b, c.a * alpha_mul)



## Override: layout from UISettingsManager
func _apply_layout_from_manager() -> void:
	_set_layout(UISettingsManager.layout_style)


## Override: background shader from UISettingsManager
func _apply_shader_from_manager() -> void:
	var mat := ShaderMaterial.new()
	match UISettingsManager.shader_effect:
		UISettingsManager.ShaderEffect.GRID_WAVE:      mat.shader = SHADER_GRID
		UISettingsManager.ShaderEffect.CYBER_HEXAGONS: mat.shader = SHADER_HEX
		UISettingsManager.ShaderEffect.NEON_ORBS:      mat.shader = SHADER_ORBS
		UISettingsManager.ShaderEffect.CRT_SCANLINES:  mat.shader = SHADER_SCAN
		UISettingsManager.ShaderEffect.STAR_WARP:      mat.shader = SHADER_WARP
	bg_rect.material = mat


# ─────────────────────────────────────────────────────────────────
# Layout helper (shared between inspector + UISettingsManager)
# ─────────────────────────────────────────────────────────────────

func _set_layout(ls: int) -> void:
	match ls:
		LayoutStyle.CENTER_STACK, UISettingsManager.LayoutStyle.CENTER_STACK:
			button_container.anchors_preset = Control.PRESET_CENTER
			button_container.offset_left  = -140.0; button_container.offset_top    = -60.0
			button_container.offset_right =  100.0; button_container.offset_bottom = 200.0
			title_container.anchors_preset = Control.PRESET_CENTER_TOP
			title_container.offset_left = -180.0; title_container.offset_top = 110.0; title_container.offset_right = 180.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		LayoutStyle.LEFT_ALIGNED, UISettingsManager.LayoutStyle.LEFT_RAIL:
			button_container.anchors_preset = Control.PRESET_CENTER_LEFT
			button_container.offset_left  =  30.0; button_container.offset_top    = -40.0
			button_container.offset_right = 240.0; button_container.offset_bottom = 220.0
			title_container.anchors_preset = Control.PRESET_TOP_LEFT
			title_container.offset_left = 30.0; title_container.offset_top = 110.0; title_container.offset_right = 300.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		LayoutStyle.BOTTOM_PANEL, UISettingsManager.LayoutStyle.BOTTOM_PANEL:
			button_container.anchors_preset = Control.PRESET_CENTER_BOTTOM
			button_container.offset_left  = -140.0; button_container.offset_top    = -320.0
			button_container.offset_right =  140.0; button_container.offset_bottom =  -60.0
			title_container.anchors_preset = Control.PRESET_CENTER_TOP
			title_container.offset_left = -180.0; title_container.offset_top = 130.0; title_container.offset_right = 180.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		UISettingsManager.LayoutStyle.TOP_BAR:
			button_container.anchors_preset = Control.PRESET_CENTER_TOP
			button_container.offset_left  = -180.0; button_container.offset_top    =  72.0
			button_container.offset_right =  180.0; button_container.offset_bottom = 130.0
			# Make buttons horizontal for top bar
			title_container.anchors_preset = Control.PRESET_CENTER
			title_container.offset_left = -180.0; title_container.offset_top = 160.0; title_container.offset_right = 180.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


# ─────────────────────────────────────────────────────────────────
# Procedural bounce loop
# ─────────────────────────────────────────────────────────────────

func _start_ball_bounce_loop() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(anim_ball, "position:y", ball_base_y - ball_jump_height, 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(anim_ball, "scale", Vector2(24, 30), 0.45)
	tw.tween_property(anim_ball, "position:y", ball_base_y, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(anim_ball, "scale", Vector2(30, 22), 0.4)
	tw.tween_property(anim_ball, "scale", Vector2(36, 18), 0.08)
	tw.parallel().tween_property(anim_platform, "scale:y", 10.0, 0.08)
	tw.tween_property(anim_ball, "scale", Vector2(27, 27), 0.08)
	tw.parallel().tween_property(anim_platform, "scale:y", 16.0, 0.08)


## Override: bounce animation from UISettingsManager
func _apply_bounce_from_manager() -> void:
	if not anim_ball:
		return
	# Stop any running tweens/animations first
	if anim_player and anim_player.is_playing():
		anim_player.stop()

	match UISettingsManager.bounce_style:
		UISettingsManager.BounceType.TWEEN_PROCEDURAL:
			ball_base_y = anim_ball.position.y
			_start_ball_bounce_loop()
		UISettingsManager.BounceType.ANIMATION_PLAYER_CLASSIC:
			if anim_player:
				anim_player.play("classic_bounce")
		UISettingsManager.BounceType.ANIMATION_PLAYER_HIGH_JUMP:
			if anim_player:
				anim_player.play("high_jump_spin")
		UISettingsManager.BounceType.ANIMATION_PLAYER_DOUBLE_HOP:
			if anim_player:
				anim_player.play("double_hop")


# ─────────────────────────────────────────────────────────────────
# Options → opens Style Lab
# ─────────────────────────────────────────────────────────────────

func _on_options_pressed() -> void:
	if _style_lab_instance:
		return
	_style_lab_instance = STYLE_LAB_SCRIPT.new()
	_style_lab_instance.closed.connect(_on_style_lab_closed)
	add_child(_style_lab_instance)


func _on_style_lab_closed() -> void:
	_style_lab_instance = null


# ─────────────────────────────────────────────────────────────────
# Other button handlers
# ─────────────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	GameManager.start_game()


func _show_wip(title_txt: String, message: String) -> void:
	wip_title.text = title_txt
	wip_msg.text   = message
	wip_modal.visible = true
	wip_modal.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(wip_modal, "modulate:a", 1.0, 0.2)
	var box = $WipModal/ModalBox
	box.scale = Vector2(0.6, 0.6)
	box.pivot_offset = box.size / 2
	var tw2 := create_tween()
	tw2.tween_property(box, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_wip() -> void:
	var tw := create_tween()
	tw.tween_property(wip_modal, "modulate:a", 0.0, 0.15)
	await tw.finished
	wip_modal.visible = false


func _on_btn_hover(btn: Button, entering: bool) -> void:
	var anim_params := UISettingsManager.get_animation_params()
	var h_scale: Vector2 = anim_params["hover_scale"] if entering else Vector2.ONE
	var dur: float = max(float(anim_params["duration"]) * 0.4, 0.05)
	var trans: int = anim_params["trans_type"]
	var eas: int   = anim_params["ease_type"]
	btn.pivot_offset = btn.size / 2.0
	var tw := create_tween()
	tw.tween_property(btn, "scale", h_scale, dur).set_trans(trans).set_ease(eas)
