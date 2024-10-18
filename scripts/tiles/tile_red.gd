extends Tile

func _on_created() -> void:
	type = 'RED'

func _on_just_pressed(object_pressing: Object) -> void:
	if object_pressing is Item:
		object_pressing.die(self)
	
	$ActivationParticles.restart()
	$ActivationParticles.emitting = true
