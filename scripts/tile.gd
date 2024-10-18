class_name Tile extends StaticBody3D

# TODO Make it so the tile can detect neghiboring tiles and update when they are updated (Neighbors array)
# TODO Add tile death

# Tile
@onready var holding_timer = $Holding
var pressed_by = []
var type = 'DEFAULT'
var is_pressed = false

# Animations
@onready var animation_player = $Animator
const animations = {
	'press': 'DOWN',
	'lift': 'UP',
}

# Signals for inherited scenes
signal created
signal just_pressed (object_pressing:Object)
signal just_unpressed (object_left:Object)
# signal being_pressed (object_pressing:Object)
# signal idle

# Tile

func set_is_pressed(value:bool):
	if is_pressed == value: return
	
	var is_pressed_before = is_pressed
	
	if pressed_by.size() != 0:
		is_pressed = true
		
		var object_pressing = pressed_by[0]
		
		just_pressed.emit(object_pressing)
		
		if is_pressed_before != is_pressed:
			print(type, ' tile pressed by ', object_pressing.name)
		else:
			print(type, ' tile press time extended by ', object_pressing.name)
			return
	else:
		is_pressed = value
		print(type + ' tile', ' pressed' if is_pressed else ' lifted')
	
	if is_pressed:
		animation_player.play(animations.press)
		just_pressed.emit()
	else:
		animation_player.play(animations.lift)
		just_unpressed.emit()

func add_object_pressing(object:Object):
	if object == null: return
	if object in pressed_by: return
	if object is Item and (object.is_dead or object.is_picked_up): return
	
	pressed_by.append(object)
	set_is_pressed(true)

func remove_object_pressing(object:Object):
	pressed_by.erase(object)
	
	set_is_pressed(false)

# Holding

# NOTE Could add an id arg
func hold_pressed(duration:float, force_overwrite:bool = true):
	if duration < holding_timer.time_left and not force_overwrite: return
	
	add_object_pressing(holding_timer)
	holding_timer.wait_time = duration
	holding_timer.start(0)

func stop_holding():
	holding_timer.stop()

# General

# When using _init the signal do esnt reach inherited scene script
func _ready() -> void:
	created.emit()

func _on_detector_body_entered(body:Node3D) -> void:
	add_object_pressing(body)

func _on_detector_body_exited(body:Node3D) -> void:
	remove_object_pressing(body)

func _on_holding_timeout() -> void:
	remove_object_pressing(holding_timer)
