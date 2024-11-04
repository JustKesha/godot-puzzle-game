class_name Game extends Node

# Progression
@onready var save_manager = SaveManager.new()
@onready var player:Player = $Player

# Items
@onready var item_father = $Items
const items = {
	# NOTE These keys are item types (look up items metadata / item.type)
	'CUBE': preload("res://objects/items/item_cube.tscn"),
	'STEW': preload("res://objects/items/item_stew.tscn"),
}

# Tiles
@onready var tile_father = $Tiles

# Progression

func restart():
	# Currently restarting also loads the default save file, even tho all the scripts i made are suited for multiple save files im only using one
	Global.start_demo_from_save_file()

func save(save_name:String = Global.DEFAULT_SAVE_FILE_NAME):
	var save_data = save_manager.generate_save_data(self)
	
	save_manager.write_save_file(save_name, save_data)

func load_save_file(save_name:String = Global.DEFAULT_SAVE_FILE_NAME):
	save_manager.load_save_file(save_name, self)

# Items

func spawn_item(item_packed_scene:Resource, position:Vector3) -> Item:
	var new_item = item_packed_scene.instantiate()
	
	new_item.position = position
	
	item_father.add_child(new_item)
	
	return new_item

# Silly

func _ready():
	print('Started a demo game')
