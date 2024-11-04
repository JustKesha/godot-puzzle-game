class_name SaveManager extends Resource

const SAVE_DIRECTORY = "user://"

func get_save_path(save_name:String) -> String:
	return SAVE_DIRECTORY + save_name + ".tres"

func generate_save_data(player:Player) -> Save:
	var save_resource = Save.new()
	
	save_resource.player_position = player.global_position
	
	return save_resource

func read_save_data(save:Save, player:Player) -> void:
	player.global_position = save.player_position

func write_save_file(save_name:String, save:Save) -> void:
	var path = get_save_path(save_name)
	var error = ResourceSaver.save(save, path)
	
	if error:
		print('Failed to save data:\n', error)
		push_error(error)
	else:
		print('Game data saved into ', save_name, '')

func load_save_file(save_name:String, player:Player) -> void:
	var path = get_save_path(save_name)
	
	if not ResourceLoader.exists(path):
		push_error('Couldnt find a save file by ', path)
		return
	
	print('Loading a ', save_name, ' save file')
	
	var save = load(path)
	read_save_data(save, player)