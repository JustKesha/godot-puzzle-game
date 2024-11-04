extends Tile

func _on_created() -> void:
	type = 'YELLOW'

func _on_just_pressed(object_pressing: Object) -> void:
	game.save()
