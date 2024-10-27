class_name Pointer extends Node3D

@onready var animation_player = $Animator
const BOOST_VECTOR = Vector3.UP * 1.25
var is_at_rest:bool

func set_is_at_rest(value:bool):
	is_at_rest = value
	
	visible = !is_at_rest
	
	if is_at_rest:
		animation_player.stop()
	else:
		animation_player.play("POINT")

func point_at(object:Object) -> void:
	if object == null:
		rest()
		return
	
	rest(false)
	global_position = object.global_position + BOOST_VECTOR

# For ease of use
func rest(value:bool = true):
	set_is_at_rest(value)

func _ready() -> void:
	rest()
