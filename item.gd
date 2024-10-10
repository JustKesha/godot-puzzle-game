class_name Item extends RigidBody3D

# Item
var is_picked_up = false

# Scale
@onready var SCALING_CHILDREN = [ $Hitbox, $Model, ]
const SCALE_SPEED = 4
const DEFAULT_SCALE = 1
const PICKED_UP_SCALE = .45
var current_scale = DEFAULT_SCALE
var aimed_scale:float
var is_aimed_scale_reached = false
var scale_direction:int

# Rotation
@onready var model = $Model
var DEFAULT_ROTATION_SPEED = .012
var PICKED_UP_ROTATION_SPEED = -DEFAULT_ROTATION_SPEED / 2
var rotation_speed = DEFAULT_ROTATION_SPEED

# Animations
@onready var animation_player = $Animator

# Item

func set_picked_up(value:bool):
	is_picked_up = value
	
	if is_picked_up:
		set_aimed_scale(PICKED_UP_SCALE)
		set_rotation_speed(PICKED_UP_ROTATION_SPEED)
		play_animation('RESET')
	else:
		set_aimed_scale(DEFAULT_SCALE)
		set_rotation_speed(DEFAULT_ROTATION_SPEED)
		play_animation('default')
		
	print('Item picked up status was changed')

# Scale

func set_aimed_scale(value:float):
	if value == current_scale: return
	
	aimed_scale = value
	is_aimed_scale_reached = false
	scale_direction = 1 if aimed_scale > current_scale else -1

func update_scale(delta:float):
	if is_aimed_scale_reached: return
	
	# https://github.com/godotengine/godot/issues/5734
	# that was a time not well spent
	
	current_scale += SCALE_SPEED * scale_direction * delta
	
	if (scale_direction > 0 and current_scale > aimed_scale or
		scale_direction < 0 and current_scale < aimed_scale):
		current_scale = aimed_scale
	
	for scaling_child in SCALING_CHILDREN:
		scaling_child.scale = Vector3(current_scale, current_scale, current_scale)
	
	is_aimed_scale_reached = current_scale == aimed_scale
	
	if is_aimed_scale_reached:
		scale_direction = 0

# Rotation

func set_rotation_speed(value:float):
	rotation_speed = value

func apply_rotation():
	# I couldnt figure out a way to do this smoothly using animation, there might not be one
	model.rotate_y(rotation_speed)

# Animations

func play_animation(name:String):
	animation_player.play(name)

# General

func _ready():
	play_animation('default')

func _process(delta: float) -> void:
	update_scale(delta)
	apply_rotation()
