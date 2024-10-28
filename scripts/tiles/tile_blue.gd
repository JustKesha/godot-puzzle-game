extends Tile

func _on_created() -> void:
	type = 'BLUE'

func _on_just_pressed(object_pressing: Object) -> void:
	# Godot doesnt allow to trigger one shot particles more than 1 time in set lifespan
	# Could make particle system for multi use one shot particles but thats an overshot imo
	$ActivationParticles.restart()
	$ActivationParticles.emitting = true
