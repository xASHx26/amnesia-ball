extends Node
## Global game manager autoload.
## Tracks jump count, level state, carried over jumps, and handles level transitions.

# === Signals ===
signal jump_used(remaining: int)
signal level_started(remaining: int)
signal level_completed(level_num: int)
signal game_over

# === Constants ===
const MAX_JUMP_CAP: int = 10
const LEVELS_PER_STAGE: int = 3

# === State ===
var current_level: int = 1
var max_jumps: int = 3
var jumps_remaining: int = 3
var carried_over_jumps: int = 0
var is_level_complete: bool = false
var is_game_over: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Returns current stage number (e.g., Levels 1-3 -> Stage 1, Levels 4-6 -> Stage 2).
func get_stage(level_num: int = -1) -> int:
	var lvl := current_level if level_num == -1 else level_num
	return ((lvl - 1) / LEVELS_PER_STAGE) + 1


## Returns 1-based level index within the current stage (1, 2, or 3).
func get_level_in_stage(level_num: int = -1) -> int:
	var lvl := current_level if level_num == -1 else level_num
	return ((lvl - 1) % LEVELS_PER_STAGE) + 1


## Call this at the start of each level to set the jump budget.
func setup_level(level_num: int, base_jumps: int) -> void:
	current_level = level_num

	# Reset carried over jumps when starting a new stage (e.g., Level 1, Level 4, Level 7)
	if get_level_in_stage(level_num) == 1:
		carried_over_jumps = 0

	# Add carried over jumps from previous level in the same stage, capped strictly at MAX_JUMP_CAP (10)
	jumps_remaining = min(base_jumps + carried_over_jumps, MAX_JUMP_CAP)
	max_jumps = jumps_remaining
	is_level_complete = false
	is_game_over = false
	level_started.emit(jumps_remaining)


## Returns true if player is allowed to jump.
func can_jump() -> bool:
	return jumps_remaining > 0 and not is_level_complete and not is_game_over


## Deducts 1 jump when the ball reaches a new platform.
func use_jump() -> bool:
	if is_level_complete or is_game_over:
		return false
	if jumps_remaining <= 0:
		return false

	jumps_remaining -= 1
	jump_used.emit(jumps_remaining)

	return true


## Called by the ball when it lands on the flag/goal platform.
func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true

	# Save remaining jumps to carry over to the next level (capped at MAX_JUMP_CAP)
	carried_over_jumps = min(jumps_remaining, MAX_JUMP_CAP)
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
		# Reset game to level 1 and clear carried over jumps
		current_level = 1
		carried_over_jumps = 0
		get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")
