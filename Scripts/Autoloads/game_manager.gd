extends Node
## Global game manager autoload with JSON save system, stage unlock tracking,
## dynamic level scanning, jump budget calculations, and level transitions.

# === Signals ===
signal jump_used(remaining: int)
signal level_started(remaining: int)
signal level_completed(level_num: int)
signal game_over

# === Constants ===
const MAX_JUMP_CAP: int = 10
const LEVELS_PER_STAGE: int = 3
const SAVE_PATH: String = "user://save_data.json"

# === State ===
var current_level: int = 1
var max_jumps: int = 3
var jumps_remaining: int = 3
var carried_over_jumps: int = 0
var is_level_complete: bool = false
var is_game_over: bool = false

# === Save Data Structure ===
var save_data: Dictionary = {
	"unlocked_stages": [1],
	"levels": {} # Key: "s1_l1" -> {"completed": true, "saved_jumps": 2, "stars": 3}
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


# === JSON Save / Load System ===

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_str := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary:
		save_data = parsed
		var unlocked: Array = []
		for item in save_data.get("unlocked_stages", [1]):
			unlocked.append(int(item))
		if not 1 in unlocked:
			unlocked.append(1)
		save_data["unlocked_stages"] = unlocked
		if not save_data.has("levels"):
			save_data["levels"] = {}


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()


## Returns saved level dictionary for a given level number, or default empty record.
func get_level_record(level_num: int) -> Dictionary:
	var key := "s%d_l%d" % [get_stage(level_num), get_level_in_stage(level_num)]
	return save_data["levels"].get(key, {"completed": false, "saved_jumps": 0, "stars": 0})


## Returns true if the specified stage is unlocked. Stage 1 is always unlocked.
func is_stage_unlocked(stage_num: int) -> bool:
	if stage_num <= 1:
		return true
	for st in save_data.get("unlocked_stages", []):
		if int(st) == stage_num:
			return true
	return false


## Dynamically scans res://Scenes/Levels/ to find total existing levels.
func get_total_levels() -> int:
	var count := 0
	while ResourceLoader.exists("res://Scenes/Levels/level_%d.tscn" % (count + 1)):
		count += 1
	return max(count, 3)


## Dynamically calculates total stages based on total levels.
func get_total_stages() -> int:
	var total_lvls := get_total_levels()
	return int(ceil(float(total_lvls) / float(LEVELS_PER_STAGE)))


# === Stage & Level Helpers ===

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

	# Reset carried over jumps when starting Level 1 of any stage
	if get_level_in_stage(level_num) == 1:
		carried_over_jumps = 0
	# If entering directly via Level Selector without carried jumps set in memory, load from JSON save
	elif carried_over_jumps == 0:
		var prev_lvl := level_num - 1
		var prev_rec := get_level_record(prev_lvl)
		if prev_rec.get("completed", false):
			carried_over_jumps = prev_rec.get("saved_jumps", 0)

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

	# Save remaining jumps to carry over to the next level
	carried_over_jumps = min(jumps_remaining, MAX_JUMP_CAP)

	# Calculate stars earned (3 stars: 2+ jumps left; 2 stars: 1 jump left; 1 star: 0 jumps left)
	var stars_earned := 1
	if jumps_remaining >= 2:
		stars_earned = 3
	elif jumps_remaining == 1:
		stars_earned = 2

	# Save level record in JSON
	var key := "s%d_l%d" % [get_stage(current_level), get_level_in_stage(current_level)]
	var existing: Dictionary = save_data["levels"].get(key, {})
	var prev_saved: int = existing.get("saved_jumps", 0)
	var prev_stars: int = existing.get("stars", 0)

	save_data["levels"][key] = {
		"completed": true,
		"saved_jumps": max(jumps_remaining, prev_saved),
		"stars": max(stars_earned, prev_stars)
	}

	# If this was the last level of a stage, unlock the next stage!
	if get_level_in_stage(current_level) == LEVELS_PER_STAGE:
		var next_stage := get_stage(current_level) + 1
		if not next_stage in save_data["unlocked_stages"]:
			save_data["unlocked_stages"].append(next_stage)

	save_game()
	level_completed.emit(current_level)


## Called when the ball lands with 0 jumps remaining and NOT on the goal.
func trigger_game_over() -> void:
	if is_game_over or is_level_complete:
		return
	is_game_over = true
	game_over.emit()


## Starts a fresh game from Stage 1 - Level 1.
func start_game() -> void:
	current_level = 1
	carried_over_jumps = 0
	_load_level(1)


## Launches a level directly from the Level Selector with optional carried jumps.
func launch_level_direct(level_num: int, starting_carried_jumps: int = 0) -> void:
	current_level = level_num
	carried_over_jumps = starting_carried_jumps
	_load_level(level_num)


## Returns to the main menu home screen.
func go_to_main_menu() -> void:
	current_level = 1
	carried_over_jumps = 0
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")


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
		# If no more levels exist, return to main menu
		go_to_main_menu()
