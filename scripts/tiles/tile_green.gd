extends Tile

func _on_created() -> void:
	type = 'GREEN'

func _on_just_pressed(object_pressing: Object) -> void:
	die()
