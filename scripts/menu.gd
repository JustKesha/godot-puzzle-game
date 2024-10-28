extends CanvasLayer

# Should be moved to a global game.gd

const scene_paths = {
	'demo': "res://scenes/demo.tscn",
}

func load_scene(new_scene_path:String):
	get_tree().change_scene_to_file(new_scene_path)

func close():
	get_tree().quit()

# Buttons

func _on_button_demo_pressed() -> void:
	load_scene(scene_paths.demo)

func _on_button_exit_pressed() -> void:
	close()
