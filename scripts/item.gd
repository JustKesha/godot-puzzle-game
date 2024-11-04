class_name Item extends RigidBody3D

# Item
@onready var hitbox = $Hitbox
@onready var pickup_cd_timer = $PickupCD
@onready var death_timer = $Death
@onready var afterlife_timer = $Afterlife
@onready var death_particles = [ $DeathParticles, ]
@onready var remove_on_death = [ $Hitbox, $View, ]
const DEFAULT_PICKUP_CD = 0.5
var type:String
var death_duration = 1.0
var is_picked_up = false
var is_on_pickup_cd = false
var is_dead = false
var is_deleted = false

# Scale
@onready var scaling_children = [ $Hitbox, $View, ]
const SCALE_SPEED = 3
const SCALE_DEFAULT = 1
const SCALE_PICKED = .6
var current_scale = SCALE_DEFAULT
var target_scale = current_scale
var is_target_scale_reached = false
var scale_direction = 0

# Rotation
@onready var model = $View/Model
const DEFAULT_ROTATION_SPEED = .012
const PICKED_UP_ROTATION_SPEED = -DEFAULT_ROTATION_SPEED / 2
var rotation_speed = DEFAULT_ROTATION_SPEED

# Movement
const DEFAULT_SPEED = 5.0
const POSITION_ACCURACY = 3.0
var speed = DEFAULT_SPEED
var target_position = Vector3.ZERO
var is_in_manual_motion = false

# Animations
@onready var animation_player = $Animator
var animations = {
	'death': 'WOBBLE',
	'default': 'FLOAT',
	'picked': 'RESET',
	'delete': 'RESET',
}

# Physics
@onready var neighborhood_area = $Neighborhood

# Item

func set_hitbox_disabled(value:bool):
	# Used in player.show_inventory, but player.show_inventory is never used atm
	hitbox.disabled = value

# WARNING Not disabling hitbox on picked up items should cause problems like tile activation, doesnt seem to be the case
# Tho this does allow collision for inventory items which isnt good
func set_picked_up(value:bool, soft_action:bool = false, disable_hitbox:bool = value) -> bool:
	if is_dead: return false
	if is_on_pickup_cd and soft_action: return false
	if is_picked_up == value: return false
	
	is_picked_up = value
	set_on_pickup_cd()
	set_hitbox_disabled(disable_hitbox)
	
	if is_picked_up:
		freeze = true
		wake_up_neighbors()
		set_target_scale(SCALE_PICKED)
		set_rotation_speed(PICKED_UP_ROTATION_SPEED)
		linear_velocity = Vector3.ZERO
		animation_player.play(animations.picked)
	else:
		freeze = false
		linear_velocity = Vector3.ZERO
		stop_moving()
		set_target_scale(SCALE_DEFAULT)
		set_rotation_speed(DEFAULT_ROTATION_SPEED)
		animation_player.play(animations.default)
	
	return true

func set_on_pickup_cd(duration:float = DEFAULT_PICKUP_CD):
	if duration == 0:
		pickup_cd_timer.stop()
		is_on_pickup_cd = false
		return
	
	is_on_pickup_cd = true
	pickup_cd_timer.wait_time = duration
	pickup_cd_timer.start(0)

func reset_pickup_cd():
	set_on_pickup_cd(0)

func delete():
	if is_deleted: return
	
	is_deleted = true
	is_dead = true
	afterlife_timer.start(0)
	animation_player.play(animations.delete)
	freeze = true
	for child in remove_on_death:
		child.queue_free()
	for particles in death_particles:
		particles.emitting = true

func die(source_object:Object = null, death_time:float = death_duration):
	if is_dead: return
	if death_time <= .05:
		delete()
		return
	
	is_dead = true
	freeze = true # NOTE Can be removed if you want it bouncy when it hits the lava or smthn
	death_timer.wait_time = death_time
	death_timer.start(0)
	animation_player.play(animations.death)

# Scale

func set_target_scale(value:float):
	if is_dead: return
	if target_scale == value: return
	
	target_scale = value
	is_target_scale_reached = false
	scale_direction = 1 if target_scale > current_scale else -1

func update_scale(delta:float):
	if is_deleted: return
	if is_target_scale_reached: return
	
	# https://github.com/godotengine/godot/issues/5734
	# that was a time not well spent
	
	current_scale += SCALE_SPEED * scale_direction * delta
	
	if (scale_direction > 0 and current_scale > target_scale or
		scale_direction < 0 and current_scale < target_scale):
		current_scale = target_scale
	
	for scaling_child in scaling_children:
		scaling_child.scale = Vector3(current_scale, current_scale, current_scale)
	
	is_target_scale_reached = current_scale == target_scale
	
	if is_target_scale_reached:
		scale_direction = 0

# Rotation

func set_rotation_speed(value:float):
	rotation_speed = value

func apply_rotation():
	model.rotate_y(rotation_speed)

# Movement

func are_vectors_roughly_equal(vector_a:Vector3, vector_b:Vector3, accuracy:float) -> bool:
	var accuracy_vec = Vector3(0.1 ** accuracy, 0.1 ** accuracy, 0.1 ** accuracy)
	
	return snapped(vector_a, accuracy_vec) == snapped(vector_b, accuracy_vec)

# NOTE Could perhaps do movement with forces to be able to use it in non picked state
func update_position(delta:float):
	if not is_in_manual_motion: return
	if are_vectors_roughly_equal(global_position, target_position, POSITION_ACCURACY):
		stop_moving()
		return
	
	global_position = global_position.lerp(target_position, speed * delta)
	linear_velocity = Vector3.ZERO

func set_to_position(position_vector:Vector3):
	global_position = position_vector

func move_to_position(position_vector:Vector3, new_speed:float = DEFAULT_SPEED):
	speed = new_speed
	target_position = position_vector
	is_in_manual_motion = true
	freeze = true

func stop_moving():
	is_in_manual_motion = false
	freeze = false

# Physics

func wake_up_neighbors(velocity:Vector3 = Vector3(0, 1, 0)):
	# Could also just set can_sleep to false in _ready() instead
	# Docs https://docs.godot.community/classes/class_rigidbody3d.html#class-rigidbody3d-property-can-sleep
	for neighbor in neighborhood_area.get_overlapping_bodies():
		if not neighbor is RigidBody3D: continue
		# Changing sleep state same frame as disabling hitbox doesnt help
		neighbor.linear_velocity += velocity

# General

func _ready():
	# Using metadata bc i believe many items wont be needing a script, i plan to keep most of the code in tiles and other objects
	type = get_meta('type')
	animation_player.play(animations.default)

func _process(delta:float):
	update_position(delta)
	
	if is_deleted: return
	
	update_scale(delta)
	
	if is_dead: return
	
	apply_rotation()

func _on_death_timeout() -> void:
	delete()

func _on_afterlife_timeout() -> void:
	queue_free()

func _on_pickup_cd_timeout() -> void:
	is_on_pickup_cd = false
