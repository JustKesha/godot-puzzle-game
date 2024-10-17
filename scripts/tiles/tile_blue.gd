extends Tile

func _on_created() -> void:
	type = 'BLUE'

func _on_just_pressed() -> void:
	# BUG Godot doesnt allow to trigger one shot particles more than 1 time in set lifespan
	# Could reate a particle spawner function in autoload game.gd, for one shot particles that need to be used multiple times (like here)
	$ActivationParticles.restart()
	$ActivationParticles.emitting = true
