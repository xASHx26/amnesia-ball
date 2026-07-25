extends Node2D


@onready var mesh: MeshInstance2D = $MeshInstance2D
@onready var dust_particles: GPUParticles2D = $DustParticles
var is_popping: bool = false


## Called by the ball when it lands on a new platform.
## Blinks the platform, then bursts into dust particles and disappears.
func pop() -> void:
	if is_popping:
		return
	is_popping = true

	# Disable collision immediately so the ball can't land on it again
	var static_body = $StaticBody2D
	if static_body:
		static_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

	# --- Phase 1: Blink (flash on/off rapidly) ---
	var blink_tween = create_tween()
	var blink_count := 4
	var blink_speed := 0.08
	for i in blink_count:
		blink_tween.tween_property(mesh, "modulate:a", 0.15, blink_speed) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		blink_tween.tween_property(mesh, "modulate:a", 1.0, blink_speed) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# One final fast blink to very dim
	blink_tween.tween_property(mesh, "modulate:a", 0.1, 0.04)
	await blink_tween.finished

	# --- Phase 2: Burst into dust particles ---
	mesh.visible = false
	dust_particles.emitting = true

	# Wait for particles to finish their lifetime then clean up
	await get_tree().create_timer(dust_particles.lifetime + 0.1).timeout
	queue_free()
