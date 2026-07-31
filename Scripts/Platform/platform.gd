extends Node2D

@export var is_enhanced: bool = false
@export var light_blue_color: Color = Color(0.39, 0.71, 0.96, 1.0)
@export var dark_blue_color: Color = Color(0.08, 0.35, 0.75, 1.0)

@onready var mesh: MeshInstance2D = $MeshInstance2D
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

var is_popping: bool = false
var is_popped_enhanced: bool = false
var is_reappeared: bool = false
var reappear_area: Area2D = null
var initial_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	initial_scale = scale
	if is_enhanced:
		add_to_group("enhanced_platform")
		mesh.modulate = light_blue_color
		# Override dust particle base color for blue-themed effects
		var mat := dust_particles.process_material as ParticleProcessMaterial
		if mat:
			mat = mat.duplicate() as ParticleProcessMaterial
			mat.color = light_blue_color
			dust_particles.process_material = mat
		_setup_reappear_area()


func _setup_reappear_area() -> void:
	reappear_area = Area2D.new()
	reappear_area.name = "ReappearArea"
	reappear_area.collision_layer = 0
	reappear_area.collision_mask = 1  # Detect Ball (layer 1)

	var area_shape := CollisionShape2D.new()
	if collision_shape and collision_shape.shape:
		area_shape.shape = collision_shape.shape.duplicate()

	reappear_area.add_child(area_shape)
	if collision_shape:
		area_shape.position = collision_shape.position

	add_child(reappear_area)
	reappear_area.body_entered.connect(_on_reappear_area_body_entered)


func _on_reappear_area_body_entered(body: Node2D) -> void:
	if is_popped_enhanced and not is_reappeared:
		if body.is_in_group("ball") or body.name == "Ball" or body.has_method("trigger_death"):
			if body is CharacterBody2D:
				var ball = body as CharacterBody2D
				# Only trigger reappear when the ball is actually falling downward
				if ball.velocity.y > 0:
					reappear(ball)


## Called by the ball when it lands on a new platform.
func pop() -> void:
	if is_popping:
		return
	is_popping = true

	# Disable collision immediately so the ball can't land on it again
	if static_body:
		static_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

	if is_enhanced:
		# --- Enhanced Special Disappearing Animation ---
		dust_particles.modulate = light_blue_color if not is_reappeared else dark_blue_color
		
		var blink_tween = create_tween()
		# Fast energy pulse effect
		for i in 4:
			blink_tween.tween_property(mesh, "modulate", Color.WHITE, 0.05)
			blink_tween.tween_property(mesh, "modulate", light_blue_color if not is_reappeared else dark_blue_color, 0.05)
		
		# Shrink and disappear pulse
		blink_tween.tween_property(self, "scale", initial_scale * 1.15, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		blink_tween.tween_property(self, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await blink_tween.finished

		mesh.visible = false
		dust_particles.emitting = true

		if not is_reappeared:
			is_popped_enhanced = true
			# Reset scale back to initial scale for when it re-appears later
			scale = initial_scale
		else:
			await get_tree().create_timer(dust_particles.lifetime + 0.1).timeout
			queue_free()
	else:
		# --- Standard Platform Pop ---
		var blink_tween = create_tween()
		var blink_count := 4
		var blink_speed := 0.08
		for i in blink_count:
			blink_tween.tween_property(mesh, "modulate:a", 0.15, blink_speed) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			blink_tween.tween_property(mesh, "modulate:a", 1.0, blink_speed) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		blink_tween.tween_property(mesh, "modulate:a", 0.1, 0.04)
		await blink_tween.finished

		mesh.visible = false
		dust_particles.emitting = true
		await get_tree().create_timer(dust_particles.lifetime + 0.1).timeout
		queue_free()


## Triggered when player falls into popped enhanced platform's area from above.
func reappear(ball: CharacterBody2D = null) -> void:
	if not is_popped_enhanced or is_reappeared:
		return

	is_popped_enhanced = false
	is_reappeared = true
	is_popping = false

	# Re-enable solid collision
	if static_body:
		static_body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
		# Disable the reappear sensor — it has served its purpose
		if reappear_area:
			reappear_area.set_deferred("monitoring", false)

	# Change mesh color to Dark Blue
	mesh.modulate = dark_blue_color
	mesh.visible = true

	# --- Special Elastic Re-appearing Animation ---
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", initial_scale * 1.2, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", initial_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Enhanced particle explosion for reappearing
	var mat := dust_particles.process_material as ParticleProcessMaterial
	if mat:
		mat = mat.duplicate() as ParticleProcessMaterial
		mat.color = dark_blue_color
		dust_particles.process_material = mat
	dust_particles.modulate = Color.WHITE
	dust_particles.emitting = true

	# Give the ball a tiny upward bounce so it lands stably on the reappeared platform
	if ball and is_instance_valid(ball):
		ball.velocity.y = -200.0  # small auto-bounce to stabilize
