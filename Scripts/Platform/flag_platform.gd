extends Node2D
## Flag/goal platform — the final platform in a level.
## When the ball lands here, the level is completed.
## Does NOT pop like normal platforms.

@onready var mesh: MeshInstance2D = $MeshInstance2D
@onready var flag_sprite: MeshInstance2D = $FlagPole


func _ready() -> void:
	add_to_group("goal")


## Override: flag platforms don't disappear.
func pop() -> void:
	# Do nothing — goal platforms are permanent
	pass


## Called by the ball when it detects landing on this goal platform.
func celebrate() -> void:
	# Quick scale bounce to feel satisfying
	var tw := create_tween()
	tw.tween_property(mesh, "scale", mesh.scale * 1.15, 0.1) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mesh, "scale", mesh.scale, 0.15) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
