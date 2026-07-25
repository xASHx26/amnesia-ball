extends Node2D
## Fireworks celebration effect.
## Instance this scene, add it to the tree, and it auto-plays + auto-frees.


func _ready() -> void:
	# Start all particle emitters
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true

	# Find the longest lifetime among all particle nodes
	var max_lifetime: float = 0.0
	for child in get_children():
		if child is GPUParticles2D:
			max_lifetime = max(max_lifetime, child.lifetime)

	# Auto-free after all particles are done
	await get_tree().create_timer(max_lifetime + 0.3).timeout
	queue_free()
