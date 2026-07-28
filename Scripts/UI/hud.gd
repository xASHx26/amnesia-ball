extends CanvasLayer
## HUD — displays jump counter during gameplay,
## and shows level-complete / game-over overlay screens.

const FIREWORKS_SCENE: PackedScene = preload("res://Scenes/Effects/fireworks.tscn")

enum UIStyle {

	MODERN_GLASS,     ## Theme 1: Glassmorphic frosted card with subtle white glow & blue/cyan accent buttons
	NEON_CYBER,       ## Theme 2: Cyberpunk dark theme with vibrant electric cyan glow & neon borders
	MINIMAL_SLATE,    ## Theme 3: Sleek dark slate card with warm gold borders & elegant buttons
	ARCADE_SYNTHWAVE  ## Theme 4: Retro synthwave with hot magenta & neon teal contrast
}

@export var ui_style: UIStyle = UIStyle.MODERN_GLASS:
	set(value):
		ui_style = value
		if is_node_ready():
			_apply_ui_style()

@onready var pause_btn: Button = $GameplayUI/PauseBtn
@onready var jump_label: Label = $GameplayUI/JumpLabel
@onready var level_label: Label = $GameplayUI/LevelLabel
@onready var overlay: ColorRect = $Overlay
@onready var pause_card: PanelContainer = $Overlay/PauseCard
@onready var overlay_title: Label = $Overlay/PauseCard/VBoxContainer/TitleLabel
@onready var resume_btn: Button = $Overlay/PauseCard/VBoxContainer/ResumeBtn
@onready var next_level_btn: Button = $Overlay/PauseCard/VBoxContainer/NextLevelBtn
@onready var retry_btn: Button = $Overlay/PauseCard/VBoxContainer/RetryBtn
@onready var main_menu_btn: Button = $Overlay/PauseCard/VBoxContainer/MainMenuBtn
@onready var quit_btn: Button = $Overlay/PauseCard/VBoxContainer/QuitBtn
@onready var touch_controls: Control = $GameplayUI/ButtonPanel


func _ready() -> void:
	# Hide overlay and reset pause at start
	overlay.visible = false
	get_tree().paused = false

	# Apply initial UI style theme
	_apply_ui_style()

	# Connect to GameManager signals
	GameManager.jump_used.connect(_on_jump_used)
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)

	# Connect buttons
	pause_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	next_level_btn.pressed.connect(_on_next_level_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Initial display
	_update_jump_display(GameManager.jumps_remaining)
	_update_level_label()


func _apply_ui_style() -> void:
	if not pause_card:
		return

	var panel_sb := StyleBoxFlat.new()
	var primary_btn_sb := StyleBoxFlat.new()
	var primary_hover_sb := StyleBoxFlat.new()
	var secondary_btn_sb := StyleBoxFlat.new()
	var secondary_hover_sb := StyleBoxFlat.new()
	var quit_btn_sb := StyleBoxFlat.new()
	var quit_hover_sb := StyleBoxFlat.new()

	match ui_style:
		UIStyle.MODERN_GLASS:
			# Glassmorphic Frosted Panel
			panel_sb.bg_color = Color(0.12, 0.16, 0.24, 0.88)
			panel_sb.set_border_width_all(1)
			panel_sb.border_color = Color(1.0, 1.0, 1.0, 0.25)
			panel_sb.set_corner_radius_all(20)
			panel_sb.shadow_color = Color(0, 0, 0, 0.5)
			panel_sb.shadow_size = 18
			panel_sb.set_content_margin_all(22)

			overlay_title.add_theme_color_override("font_color", Color(1, 1, 1))

			# Primary (Resume/Next)
			primary_btn_sb.bg_color = Color(0.18, 0.6, 0.95, 0.9)
			primary_btn_sb.set_corner_radius_all(12)
			primary_hover_sb.bg_color = Color(0.28, 0.72, 1.0, 1.0)
			primary_hover_sb.set_corner_radius_all(12)

			# Secondary (Retry/Main Menu)
			secondary_btn_sb.bg_color = Color(0.22, 0.28, 0.38, 0.75)
			secondary_btn_sb.set_border_width_all(1)
			secondary_btn_sb.border_color = Color(1.0, 1.0, 1.0, 0.15)
			secondary_btn_sb.set_corner_radius_all(12)
			secondary_hover_sb.bg_color = Color(0.3, 0.38, 0.5, 0.9)
			secondary_hover_sb.set_corner_radius_all(12)

			# Quit
			quit_btn_sb.bg_color = Color(0.7, 0.2, 0.25, 0.7)
			quit_btn_sb.set_corner_radius_all(12)
			quit_hover_sb.bg_color = Color(0.85, 0.25, 0.3, 0.9)
			quit_hover_sb.set_corner_radius_all(12)

		UIStyle.NEON_CYBER:
			# Cyberpunk Neon
			panel_sb.bg_color = Color(0.04, 0.05, 0.09, 0.95)
			panel_sb.set_border_width_all(2)
			panel_sb.border_color = Color(0.0, 0.95, 1.0, 0.9)
			panel_sb.set_corner_radius_all(14)
			panel_sb.shadow_color = Color(0.0, 0.8, 1.0, 0.35)
			panel_sb.shadow_size = 22
			panel_sb.set_content_margin_all(22)

			overlay_title.add_theme_color_override("font_color", Color(0.2, 1.0, 1.0))

			# Primary
			primary_btn_sb.bg_color = Color(0.05, 0.35, 0.55, 0.95)
			primary_btn_sb.set_border_width_all(2)
			primary_btn_sb.border_color = Color(0.0, 0.9, 1.0, 1.0)
			primary_btn_sb.set_corner_radius_all(10)
			primary_hover_sb.bg_color = Color(0.1, 0.5, 0.75, 1.0)
			primary_hover_sb.set_corner_radius_all(10)

			# Secondary
			secondary_btn_sb.bg_color = Color(0.12, 0.1, 0.22, 0.9)
			secondary_btn_sb.set_border_width_all(1)
			secondary_btn_sb.border_color = Color(0.8, 0.3, 1.0, 0.7)
			secondary_btn_sb.set_corner_radius_all(10)
			secondary_hover_sb.bg_color = Color(0.22, 0.18, 0.38, 1.0)
			secondary_hover_sb.set_corner_radius_all(10)

			# Quit
			quit_btn_sb.bg_color = Color(0.4, 0.05, 0.15, 0.9)
			quit_btn_sb.set_border_width_all(1)
			quit_btn_sb.border_color = Color(1.0, 0.2, 0.4, 0.8)
			quit_btn_sb.set_corner_radius_all(10)
			quit_hover_sb.bg_color = Color(0.6, 0.1, 0.25, 1.0)
			quit_hover_sb.set_corner_radius_all(10)

		UIStyle.MINIMAL_SLATE:
			# Minimalist Slate & Gold
			panel_sb.bg_color = Color(0.14, 0.16, 0.2, 0.96)
			panel_sb.set_border_width_all(1)
			panel_sb.border_color = Color(0.88, 0.75, 0.4, 0.7)
			panel_sb.set_corner_radius_all(12)
			panel_sb.shadow_color = Color(0, 0, 0, 0.6)
			panel_sb.shadow_size = 14
			panel_sb.set_content_margin_all(22)

			overlay_title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.65))

			# Primary
			primary_btn_sb.bg_color = Color(0.85, 0.7, 0.3, 0.9)
			primary_btn_sb.set_corner_radius_all(8)
			primary_hover_sb.bg_color = Color(0.95, 0.8, 0.4, 1.0)
			primary_hover_sb.set_corner_radius_all(8)

			# Secondary
			secondary_btn_sb.bg_color = Color(0.2, 0.23, 0.28, 0.9)
			secondary_btn_sb.set_border_width_all(1)
			secondary_btn_sb.border_color = Color(0.85, 0.7, 0.4, 0.3)
			secondary_btn_sb.set_corner_radius_all(8)
			secondary_hover_sb.bg_color = Color(0.28, 0.32, 0.4, 1.0)
			secondary_hover_sb.set_corner_radius_all(8)

			# Quit
			quit_btn_sb.bg_color = Color(0.28, 0.18, 0.2, 0.9)
			quit_btn_sb.set_corner_radius_all(8)
			quit_hover_sb.bg_color = Color(0.4, 0.22, 0.25, 1.0)
			quit_hover_sb.set_corner_radius_all(8)

		UIStyle.ARCADE_SYNTHWAVE:
			# Synthwave Magenta & Teal
			panel_sb.bg_color = Color(0.1, 0.05, 0.18, 0.95)
			panel_sb.set_border_width_all(3)
			panel_sb.border_color = Color(1.0, 0.15, 0.6, 0.9)
			panel_sb.set_corner_radius_all(8)
			panel_sb.shadow_color = Color(1.0, 0.1, 0.6, 0.4)
			panel_sb.shadow_size = 24
			panel_sb.set_content_margin_all(22)

			overlay_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.75))

			# Primary
			primary_btn_sb.bg_color = Color(0.9, 0.15, 0.55, 0.9)
			primary_btn_sb.set_corner_radius_all(6)
			primary_hover_sb.bg_color = Color(1.0, 0.25, 0.65, 1.0)
			primary_hover_sb.set_corner_radius_all(6)

			# Secondary
			secondary_btn_sb.bg_color = Color(0.05, 0.35, 0.45, 0.9)
			secondary_btn_sb.set_border_width_all(1)
			secondary_btn_sb.border_color = Color(0.2, 0.9, 0.8, 0.8)
			secondary_btn_sb.set_corner_radius_all(6)
			secondary_hover_sb.bg_color = Color(0.1, 0.48, 0.6, 1.0)
			secondary_hover_sb.set_corner_radius_all(6)

			# Quit
			quit_btn_sb.bg_color = Color(0.45, 0.08, 0.25, 0.9)
			quit_btn_sb.set_corner_radius_all(6)
			quit_hover_sb.bg_color = Color(0.65, 0.12, 0.35, 1.0)
			quit_hover_sb.set_corner_radius_all(6)

	pause_card.add_theme_stylebox_override("panel", panel_sb)

	# Apply to buttons
	for b in [resume_btn, next_level_btn]:
		b.add_theme_stylebox_override("normal", primary_btn_sb)
		b.add_theme_stylebox_override("hover", primary_hover_sb)
		b.add_theme_stylebox_override("pressed", primary_hover_sb)

	for b in [retry_btn, main_menu_btn]:
		b.add_theme_stylebox_override("normal", secondary_btn_sb)
		b.add_theme_stylebox_override("hover", secondary_hover_sb)
		b.add_theme_stylebox_override("pressed", secondary_hover_sb)

	quit_btn.add_theme_stylebox_override("normal", quit_btn_sb)
	quit_btn.add_theme_stylebox_override("hover", quit_hover_sb)
	quit_btn.add_theme_stylebox_override("pressed", quit_hover_sb)


func _update_level_label() -> void:
	var stage := GameManager.get_stage()
	var lvl_in_stage := GameManager.get_level_in_stage()
	level_label.text = "S%d • L%d" % [stage, lvl_in_stage]


func _update_jump_display(remaining: int) -> void:
	if remaining >= GameManager.MAX_JUMP_CAP:
		jump_label.text = "Jumps: %d (MAX)" % remaining
	else:
		jump_label.text = "Jumps: %d" % remaining

	# Flash red when low on jumps
	if remaining <= 1 and remaining > 0:
		jump_label.modulate = Color(1.0, 0.3, 0.2)
		var tw := create_tween()
		tw.tween_property(jump_label, "scale", Vector2(1.3, 1.3), 0.1)
		tw.tween_property(jump_label, "scale", Vector2.ONE, 0.15)
	elif remaining == 0:
		jump_label.modulate = Color(1.0, 0.15, 0.1)
	else:
		jump_label.modulate = Color.WHITE


func _on_jump_used(remaining: int) -> void:
	_update_jump_display(remaining)


func _on_level_started(remaining: int) -> void:
	get_tree().paused = false
	overlay.visible = false
	touch_controls.visible = true
	_update_jump_display(remaining)
	_update_level_label()


func _on_level_completed(level_num: int) -> void:
	# Spawn fireworks at center of screen
	var fw := FIREWORKS_SCENE.instantiate()
	fw.position = Vector2(240, 400)
	add_child(fw)

	var stage := GameManager.get_stage(level_num)
	var lvl_in_stage := GameManager.get_level_in_stage(level_num)

	# Show overlay with slight delay for fireworks to be visible
	await get_tree().create_timer(0.5).timeout
	_show_overlay("Stage %d - Level %d Complete!" % [stage, lvl_in_stage], false, true, false, true, false)


func _on_game_over() -> void:
	_show_overlay("Game Over!", false, false, true, true, false)


func _on_pause_pressed() -> void:
	get_tree().paused = true
	_show_overlay("Paused", true, false, false, true, true)


func _on_resume_pressed() -> void:
	get_tree().paused = false
	overlay.visible = false
	touch_controls.visible = true


func _show_overlay(title_text: String, show_resume: bool, show_next: bool, show_retry: bool, show_main_menu: bool, show_quit: bool) -> void:
	overlay_title.text = title_text
	resume_btn.visible = show_resume
	next_level_btn.visible = show_next
	retry_btn.visible = show_retry
	main_menu_btn.visible = show_main_menu
	quit_btn.visible = show_quit
	touch_controls.visible = false

	# Fade in the overlay
	overlay.visible = true
	overlay.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.3)

	# Scale-in the title
	overlay_title.scale = Vector2(0.5, 0.5)
	overlay_title.pivot_offset = overlay_title.size / 2
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(overlay_title, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
