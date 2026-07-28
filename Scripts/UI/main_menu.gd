extends Control
## Main Menu script handling customizable background shaders,
## layout positions, button styles, title themes, and ball animations.

enum BounceStyle {
	TWEEN_PROCEDURAL,
	ANIMATION_PLAYER_CLASSIC,
	ANIMATION_PLAYER_HIGH_JUMP,
	ANIMATION_PLAYER_DOUBLE_HOP
}

enum ShaderStyle {
	GRID_WAVE,
	CYBER_HEXAGONS,
	NEON_ORBS
}

enum LayoutStyle {
	CENTER_STACK,
	LEFT_ALIGNED,
	BOTTOM_PANEL
}

enum ButtonStyle {
	DARK_GLASS,
	SOLID_NEON,
	ROUNDED_PILL
}

enum TitleStyle {
	NEON_CYAN,
	GOLD_RETRO,
	MAGENTA_PULSE
}

# === Customizable Export Options for Mix-and-Match in Godot Inspector ===
@export_group("Menu Customization Options")
@export var bounce_style: BounceStyle = BounceStyle.ANIMATION_PLAYER_CLASSIC
@export var shader_style: ShaderStyle = ShaderStyle.GRID_WAVE
@export var layout_style: LayoutStyle = LayoutStyle.CENTER_STACK
@export var button_style: ButtonStyle = ButtonStyle.DARK_GLASS
@export var title_style: TitleStyle = TitleStyle.NEON_CYAN

# === Node References ===
@onready var bg_rect: ColorRect = $BackgroundRect
@onready var title_container: VBoxContainer = $TitleContainer
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubTitleLabel
@onready var button_container: VBoxContainer = %ButtonContainer

@onready var start_btn: Button = %StartBtn
@onready var level_select_btn: Button = %LevelSelectBtn
@onready var options_btn: Button = %OptionsBtn
@onready var credits_btn: Button = %CreditsBtn
@onready var google_play_btn: TextureButton = %GooglePlayBtn

@onready var wip_modal: ColorRect = $WipModal
@onready var wip_title: Label = %WipTitle
@onready var wip_msg: Label = %WipMsg
@onready var wip_close_btn: Button = %WipCloseBtn

@onready var anim_ball: MeshInstance2D = %AnimBall
@onready var anim_platform: MeshInstance2D = %AnimPlatform
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Preloaded Shader Materials
const SHADER_GRID = preload("res://Shaders/background_grid.gdshader")
const SHADER_HEX = preload("res://Shaders/background_hexagons.gdshader")
const SHADER_ORBS = preload("res://Shaders/background_orbs.gdshader")

var ball_base_y: float = 580.0
var ball_jump_height: float = 140.0


func _ready() -> void:
	# Hide WIP modal at start
	wip_modal.visible = false

	# Connect buttons
	start_btn.pressed.connect(_on_start_pressed)
	level_select_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/UI/level_selector.tscn"))
	options_btn.pressed.connect(func(): _show_wip("Options", "Game settings & audio controls coming soon!"))
	credits_btn.pressed.connect(func(): _show_wip("Credits", "Amnesia Ball\nDeveloped with Godot Engine 4"))
	google_play_btn.pressed.connect(func(): _show_wip("Google Play Games", "Google Play achievements & leaderboards coming soon!"))
	wip_close_btn.pressed.connect(_hide_wip)

	# Apply selected mix-and-match iterations
	_apply_all_customizations()


func _apply_all_customizations() -> void:
	_setup_bounce_animation()
	_apply_shader_style()
	_apply_layout_style()
	_apply_button_style()
	_apply_title_style()


## 1. Apply Background Shader Iteration
func _apply_shader_style() -> void:
	var mat := ShaderMaterial.new()
	match shader_style:
		ShaderStyle.GRID_WAVE:
			mat.shader = SHADER_GRID
		ShaderStyle.CYBER_HEXAGONS:
			mat.shader = SHADER_HEX
		ShaderStyle.NEON_ORBS:
			mat.shader = SHADER_ORBS
	bg_rect.material = mat


## 2. Apply Screen Layout Iteration
func _apply_layout_style() -> void:
	match layout_style:
		LayoutStyle.CENTER_STACK:
			button_container.anchors_preset = Control.PRESET_CENTER
			button_container.offset_left = -140.0
			button_container.offset_top = -60.0
			button_container.offset_right = 100.0
			button_container.offset_bottom = 200.0

			title_container.anchors_preset = Control.PRESET_CENTER_TOP
			title_container.offset_left = -180.0
			title_container.offset_top = 110.0
			title_container.offset_right = 180.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		LayoutStyle.LEFT_ALIGNED:
			button_container.anchors_preset = Control.PRESET_CENTER_LEFT
			button_container.offset_left = 30.0
			button_container.offset_top = -40.0
			button_container.offset_right = 240.0
			button_container.offset_bottom = 220.0

			title_container.anchors_preset = Control.PRESET_TOP_LEFT
			title_container.offset_left = 30.0
			title_container.offset_top = 110.0
			title_container.offset_right = 300.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		LayoutStyle.BOTTOM_PANEL:
			button_container.anchors_preset = Control.PRESET_CENTER_BOTTOM
			button_container.offset_left = -140.0
			button_container.offset_top = -320.0
			button_container.offset_right = 140.0
			button_container.offset_bottom = -60.0

			title_container.anchors_preset = Control.PRESET_CENTER_TOP
			title_container.offset_left = -180.0
			title_container.offset_top = 130.0
			title_container.offset_right = 180.0
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## 3. Apply Button Visual Style Iteration
func _apply_button_style() -> void:
	var buttons = [start_btn, level_select_btn, options_btn, credits_btn]
	for btn in buttons:
		var style_normal := StyleBoxFlat.new()
		var style_hover := StyleBoxFlat.new()
		var style_pressed := StyleBoxFlat.new()
		
		match button_style:
			ButtonStyle.DARK_GLASS:
				style_normal.bg_color = Color(0.08, 0.12, 0.22, 0.65)
				style_normal.border_color = Color(0.0, 0.8, 1.0, 0.5)
				style_normal.set_border_width_all(2)
				style_normal.set_corner_radius_all(8)
				
				style_hover.bg_color = Color(0.12, 0.2, 0.35, 0.85)
				style_hover.border_color = Color(0.0, 0.95, 1.0, 0.9)
				style_hover.set_border_width_all(2)
				style_hover.set_corner_radius_all(8)

				btn.add_theme_color_override("font_color", Color.WHITE)

			ButtonStyle.SOLID_NEON:
				style_normal.bg_color = Color(0.0, 0.65, 0.85, 0.9)
				style_normal.set_corner_radius_all(6)
				
				style_hover.bg_color = Color(0.1, 0.8, 1.0, 1.0)
				style_hover.set_corner_radius_all(6)

				btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.15))

			ButtonStyle.ROUNDED_PILL:
				style_normal.bg_color = Color(0.25, 0.12, 0.45, 0.8)
				style_normal.border_color = Color(1.0, 0.2, 0.7, 0.7)
				style_normal.set_border_width_all(2)
				style_normal.set_corner_radius_all(24)
				
				style_hover.bg_color = Color(0.35, 0.18, 0.6, 0.95)
				style_hover.border_color = Color(1.0, 0.4, 0.8, 1.0)
				style_hover.set_border_width_all(2)
				style_hover.set_corner_radius_all(24)

				btn.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))

		style_pressed = style_hover.duplicate()
		style_pressed.bg_color = style_pressed.bg_color.darkened(0.2)
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_pressed)


## 4. Apply Title Text Theme Iteration
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


## 5. Setup Selected Bounce Animation
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


## Procedural tween bounce loop
func _start_ball_bounce_loop() -> void:
	var tw := create_tween().set_loops()
	
	# 1. Rise up
	tw.tween_property(anim_ball, "position:y", ball_base_y - ball_jump_height, 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(anim_ball, "scale", Vector2(24, 30), 0.45)
	
	# 2. Fall down
	tw.tween_property(anim_ball, "position:y", ball_base_y, 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(anim_ball, "scale", Vector2(30, 22), 0.4)
	
	# 3. Squash on floor impact & platform bounce reaction
	tw.tween_property(anim_ball, "scale", Vector2(36, 18), 0.08)
	tw.parallel().tween_property(anim_platform, "scale:y", 10.0, 0.08)
	
	# 4. Recover shape
	tw.tween_property(anim_ball, "scale", Vector2(27, 27), 0.08)
	tw.parallel().tween_property(anim_platform, "scale:y", 16.0, 0.08)


func _on_start_pressed() -> void:
	GameManager.start_game()


func _show_wip(title: String, message: String) -> void:
	wip_title.text = title
	wip_msg.text = message
	
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
