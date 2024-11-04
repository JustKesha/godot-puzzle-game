class_name SaveManager extends Resource

const SAVE_DIRECTORY = "user://"

func get_save_path(save_name:String) -> String:
	return SAVE_DIRECTORY + save_name + ".tres"

func generate_save_data(game:Game) -> Save:
	var save_resource = Save.new()
	
	save_resource.player_position = game.player.global_position + Vector3.UP
	save_resource.inventory_item_types = game.player.inventory.map(func(item): return item.type)
	
	return save_resource

func read_save_data(save:Save, game:Game) -> void:
	var player:Player = game.player
	
	player.global_position = save.player_position
	
	var items_spawn_position = save.player_position + Vector3.UP * 3
	
	for item_type in save.inventory_item_types:
		var item = game.spawn_item(game.items[item_type], items_spawn_position)
		
		player.collect_item(item)

func write_save_file(save_name:String, save:Save) -> void:
	var path = get_save_path(save_name)
	var error = ResourceSaver.save(save, path)
	
	if error:
		print('Failed to save data:\n', error)
		push_error(error)
	else:
		print('Game data saved into ', save_name, '')

func load_save_file(save_name:String, game:Game) -> void:
	var path = get_save_path(save_name)
	
	if not ResourceLoader.exists(path):
		push_error('Couldnt find a save file by ', path)
		return
	
	print('Loading the ', save_name, ' save file')
	
	var save = load(path)
	read_save_data(save, game)
