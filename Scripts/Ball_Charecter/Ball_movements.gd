extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

var current_platform: Node = null    # platform the ball is ON right now
var previous_platform: Node = null   # platform the ball just LEFT


func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump with jump counter
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if GameManager.use_jump():
			velocity.y = JUMP_VELOCITY

	# Input movement
	var direction := Input.get_axis("left", "right")
	if direction and not GameManager.is_level_complete and not GameManager.is_game_over:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Detect platform collision
	_detect_platform()


func _detect_platform() -> void:
	if is_on_floor():
		var landed_on = _get_floor_platform()
		if landed_on and landed_on != current_platform:
			# Ball landed on a NEW platform
			previous_platform = current_platform
			current_platform = landed_on

			# Check if landed on Goal platform
			if current_platform.is_in_group("goal"):
				if current_platform.has_method("celebrate"):
					current_platform.celebrate()
				GameManager.complete_level()
				return

			# Pop previous platform if it exists
			if previous_platform and previous_platform.has_method("pop"):
				previous_platform.pop()
				print("POPPED: ", previous_platform.name)

			print("NOW ON: ", current_platform.name)

			# If out of jumps and landed on a normal platform -> Game Over
			if GameManager.jumps_remaining <= 0 and not GameManager.is_level_complete:
				GameManager.trigger_game_over()


func _get_floor_platform() -> Node:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collision.get_normal().y < -0.5:
			if collider.is_in_group("goal") or collider.has_method("pop"):
				return collider
			elif collider.get_parent():
				var parent = collider.get_parent()
				if parent.is_in_group("goal") or parent.has_method("pop"):
					return parent
	return null
