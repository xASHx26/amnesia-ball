extends Node2D
## Base class/script for reusable levels.
## Configures level number and maximum jumps allowed.

@export var level_number: int = 1
@export var max_jumps: int = 4


func _ready() -> void:
	GameManager.setup_level(level_number, max_jumps)
