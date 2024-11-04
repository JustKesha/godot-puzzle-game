class_name Game extends Node

# General
@onready var player = $Player
@onready var tile_father = $Tiles
@onready var item_father = $Items

# Progression
@onready var save_manager = SaveManager.new()

# Progression

func save(save_name:String = Global.DEFAULT_SAVE_FILE_NAME):
	var save_data = save_manager.generate_save_data(player)
	
	save_manager.write_save_file(save_name, save_data)

func load_save(save_name:String = Global.DEFAULT_SAVE_FILE_NAME):
	save_manager.load_save_file(save_name, player)
