extends CanvasLayer
## HUD — displays jump counter during gameplay,
## and shows level-complete / game-over overlay screens.

const FIREWORKS_SCENE: PackedScene = preload("res://Scenes/Effects/fireworks.tscn")

@onready var jump_label: Label = $GameplayUI/JumpLabel
@onready var level_label: Label = $GameplayUI/LevelLabel
@onready var overlay: ColorRect = $Overlay
@onready var overlay_title: Label = $Overlay/VBoxContainer/TitleLabel
@onready var next_level_btn: Button = $Overlay/VBoxContainer/NextLevelBtn
@onready var retry_btn: Button = $Overlay/VBoxContainer/RetryBtn


func _ready() -> void:
	# Hide overlay at start
	overlay.visible = false

	# Connect to GameManager signals
	GameManager.jump_used.connect(_on_jump_used)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_over.connect(_on_game_over)

	# Connect buttons
	next_level_btn.pressed.connect(_on_next_level_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)

	# Initial display
	_update_jump_display(GameManager.jumps_remaining)
	level_label.text = "Level %d" % GameManager.current_level


func _update_jump_display(remaining: int) -> void:
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


func _on_level_completed(level_num: int) -> void:
	# Spawn fireworks at center of screen
	var fw := FIREWORKS_SCENE.instantiate()
	fw.position = Vector2(240, 400)
	add_child(fw)

	# Show overlay with slight delay for fireworks to be visible
	await get_tree().create_timer(0.5).timeout
	_show_overlay("Level %d Complete!" % level_num, true, false)


func _on_game_over() -> void:
	_show_overlay("Out of Jumps!", false, true)


func _show_overlay(title_text: String, show_next: bool, show_retry: bool) -> void:
	overlay_title.text = title_text
	next_level_btn.visible = show_next
	retry_btn.visible = show_retry

	# Fade in the overlay
	overlay.visible = true
	overlay.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.3)

	# Scale-in the title
	overlay_title.scale = Vector2(0.5, 0.5)
	overlay_title.pivot_offset = overlay_title.size / 2
	var tw2 := create_tween()
	tw2.tween_property(overlay_title, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_next_level_pressed() -> void:
	GameManager.next_level()


func _on_retry_pressed() -> void:
	GameManager.reset_level()
