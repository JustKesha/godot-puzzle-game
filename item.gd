class_name Item extends RigidBody3D

# Item
@onready var hide_when_picked = [ $Hitbox, ]
@onready var death_timer = $Death
@onready var death_particles = [ ]
@onready var remove_on_death = [ ]
@onready var afterlife_timer = $Afterlife
@onready var delete_particles = [ $DeleteParticles, ]
@onready var remove_on_delete = [ $Hitbox, $View, ]
var is_picked_up = false
var death_duration = 1.0
var is_dead = false
var is_deleted = false

# Scale
@onready var scaling_children = [ $Hitbox, $View, ]
const SCALE_SPEED = 3
const DEFAULT_SCALE = 1
const PICKED_UP_SCALE = .6
var current_scale = DEFAULT_SCALE
var aimed_scale = DEFAULT_SCALE
var is_aimed_scale_reached = false
var scale_direction = 0

# Rotation
@onready var model = $View/Model
const DEFAULT_ROTATION_SPEED = .012
const PICKED_UP_ROTATION_SPEED = -DEFAULT_ROTATION_SPEED / 2
var rotation_speed = DEFAULT_ROTATION_SPEED

# Animations
@onready var animation_player = $Animator
var animations = {
	'death': 'WOBBLE',
	'default': 'FLOAT',
	'picked': 'RESET',
	'delete': 'RESET',
}

# Item

func set_picked_up(value:bool):
	if is_dead: return
	if is_picked_up == value: return
	
	is_picked_up = value
	
	if is_picked_up:
		set_aimed_scale(PICKED_UP_SCALE)
		set_rotation_speed(PICKED_UP_ROTATION_SPEED)
		linear_velocity = Vector3.ZERO
		animation_player.play(animations.picked)
		for shy_child in hide_when_picked:
			shy_child.disabled = true
	else:
		linear_velocity = Vector3.ZERO
		set_aimed_scale(DEFAULT_SCALE)
		set_rotation_speed(DEFAULT_ROTATION_SPEED)
		animation_player.play(animations.default)
		for shy_child in hide_when_picked:
			shy_child.disabled = false
	
	print('Picked up ' if is_picked_up else 'Dropped ', name)

func delete():
	if is_deleted: return
	
	is_deleted = true
	is_dead = true
	
	afterlife_timer.start(0)
	animation_player.play(animations.delete)
	freeze = true
	for child in remove_on_death:
		if child == null: continue
		
		child.queue_free()
	for child in remove_on_delete:
		child.queue_free()
	for particles in delete_particles:
		particles.emitting = true

func die(source_object:Object = null, death_time:float = death_duration):
	if is_dead: return
	if death_time <= .05:
		delete()
		return
	
	is_dead = true
	
	death_timer.wait_time = death_time
	death_timer.start(0)
	animation_player.play(animations.death)
	freeze = true # NOTE can be removed if you want it bouncy when it hits the lava or somthn
	for child in remove_on_death:
		child.queue_free()
	for particles in death_particles:
		particles.emitting = true

# Scale

func set_aimed_scale(value:float):
	if is_dead: return
	if value == current_scale: return
	
	aimed_scale = value
	is_aimed_scale_reached = false
	scale_direction = 1 if aimed_scale > current_scale else -1

func update_scale(delta:float):
	if is_deleted: return
	if is_aimed_scale_reached: return
	
	# https://github.com/godotengine/godot/issues/5734
	# that was a time not well spent
	
	current_scale += SCALE_SPEED * scale_direction * delta
	
	if (scale_direction > 0 and current_scale > aimed_scale or
		scale_direction < 0 and current_scale < aimed_scale):
		current_scale = aimed_scale
	
	for scaling_child in scaling_children:
		scaling_child.scale = Vector3(current_scale, current_scale, current_scale)
	
	is_aimed_scale_reached = current_scale == aimed_scale
	
	if is_aimed_scale_reached:
		scale_direction = 0

# Rotation

func set_rotation_speed(value:float):
	rotation_speed = value

func apply_rotation():
	model.rotate_y(rotation_speed)

# General

func _ready():
	animation_player.play(animations.default)

func _process(delta:float):
	if is_deleted: return
	
	update_scale(delta)
	
	if is_dead: return
	
	apply_rotation()

func _on_death_timeout() -> void:
	delete()

func _on_afterlife_timeout() -> void:
	queue_free()