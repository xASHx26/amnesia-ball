extends Node
## Global game manager autoload.
## Tracks jump count, level state, and handles level transitions.

# === Signals ===
signal jump_used(remaining: int)
signal level_completed(level_num: int)
signal game_over

# === State ===
var current_level: int = 1
var max_jumps: int = 5
var jumps_remaining: int = 5
var is_level_complete: bool = false
var is_game_over: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Call this at the start of each level to set the jump budget.
func setup_level(level_num: int, jumps: int) -> void:
	current_level = level_num
	max_jumps = jumps
	jumps_remaining = jumps
	is_level_complete = false
	is_game_over = false


## Called by the ball when the player presses jump.
## Returns true if the jump is allowed.
func use_jump() -> bool:
	if is_level_complete or is_game_over:
		return false
	if jumps_remaining <= 0:
		return false

	jumps_remaining -= 1
	jump_used.emit(jumps_remaining)

	# Check if out of jumps (game over is deferred — checked when ball lands)
	return true


## Called by the ball when it lands on the flag/goal platform.
func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	level_completed.emit(current_level)


## Called when the ball lands with 0 jumps remaining and NOT on the goal.
func trigger_game_over() -> void:
	if is_game_over or is_level_complete:
		return
	is_game_over = true
	game_over.emit()


## Load the next level.
func next_level() -> void:
	current_level += 1
	_load_level(current_level)


## Reload the current level.
func reset_level() -> void:
	_load_level(current_level)


func _load_level(level_num: int) -> void:
	var path := "res://Scenes/Levels/level_%d.tscn" % level_num
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		# No more levels — loop back to level 1 (or show a "you win" screen later)
		current_level = 1
		get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")
