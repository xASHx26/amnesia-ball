extends Node2D
## Base class/script for reusable levels.
## Configures level number, maximum jumps allowed, and level camera framing.

@export var level_number: int = 1
@export var max_jumps: int = 3

var camera: Camera2D


func _ready() -> void:
	GameManager.setup_level(level_number, max_jumps)
	_setup_camera()


func _setup_camera() -> void:
	if not has_node("Camera2D"):
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	else:
		camera = get_node("Camera2D") as Camera2D

	# Center camera horizontally (240) and frame game world in the top section
	camera.position = Vector2(240, 540)
	camera.make_current()
