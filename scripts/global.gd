extends Node

# Scene switching
const scenes = {
	'demo': preload("res://scenes/demo.tscn"),
	'menu': preload("res://scenes/menu.tscn"),
}

# Progression
const DEFAULT_SAVE_FILE_NAME = 'game_save'

# General

func close_game():
	get_tree().quit()

# Scene switching

func load_scene(new_packed_scene:Resource):
	get_tree().change_scene_to_packed(new_packed_scene)

func start_demo():
	load_scene(scenes.demo)

func start_demo_from_save(save_name:String = DEFAULT_SAVE_FILE_NAME):
	var tree = get_tree()
	
	start_demo()
	
	# WARNING .change_scene_to_packed from load_scene is not instant
	# https://github.com/godotengine/godot/issues/86286#issuecomment-1862216617
	await tree.tree_changed
	# This means tree shouldnt be changed in any other way during this load
	
	var game:Game = tree.current_scene
	
	game.load_save(save_name)

func goto_menu():
	load_scene(scenes.menu)
