class_name Player extends CharacterBody3D

# Movement
const SPEED = 5.0

# Physics
const GRAVITY = 9.8 # cannot assign ProjectSettings.get_setting("physics/3d/default_gravity") to a const directly

# Rotation
@onready var camera = $Head/Camera
@onready var body = $"."

# Camera
const SENSETIVITY = 0.001
const MIN_ROTATION = -75
const MAX_ROTATION = 85
const BOBBING_FREQUENCY = 2.5
const BOBBING_AMPLITUDE = 0.064
var bobbing_offset = 0.0

# Items
@onready var pickup_raycast = $Head/Camera/PickupRaycast
@onready var pickup_lock_object = camera
var object_aimed:Object
var item_picked:Item
var item_picked_distance = 0.0

# Movement

func apply_movement():
	var input_dir = Input.get_vector("go_left", "go_right", "go_forward", "go_backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.
	
	move_and_slide()

# Physics

# TODO Instead make player float / balance x units above ground
func apply_gravity(delta:float):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

# Rotation

func apply_rotation(event:InputEventMouseMotion):
	body.rotate_y(-event.relative.x * SENSETIVITY)
	camera.rotate_x(-event.relative.y * SENSETIVITY)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(MIN_ROTATION), deg_to_rad(MAX_ROTATION))

# Camera

# TODO Make camera slowly balance out bobbing_offset to 0 when standing still
func apply_head_bobbing(delta:float):
	bobbing_offset += delta * velocity.length() * float(is_on_floor())
	
	var local_camera_position = Vector3(
		cos(bobbing_offset * BOBBING_FREQUENCY / 2) * BOBBING_AMPLITUDE,
		sin(bobbing_offset * BOBBING_FREQUENCY) * BOBBING_AMPLITUDE,
		0
	)
	
	camera.transform.origin = local_camera_position

# Items

func update_object_aimed():
	if not pickup_raycast.is_colliding():
		object_aimed = null
		return

	var object_hit = pickup_raycast.get_collider()
	
	object_aimed = object_hit

func get_picked_up_item_lock_position() -> Vector3:
	var lock_object_position = pickup_lock_object.global_position
	var forward = -pickup_lock_object.get_global_transform().basis.z
	return lock_object_position + item_picked_distance * forward

# TODO Smooth out item movement
func update_item_picked():
	if item_picked == null: return
	item_picked.position = get_picked_up_item_lock_position() # set_position method is already taken

func pick_up_item(item:Object = object_aimed):
	if item == null:
		print('ERROR: Tried to pick up a null object')
		return
	if not item is Item:
		print('ERROR: Tried to pick up a non item object')
		return
	if item.is_dead:
		print('ERROR: Tried to pick up a dead item')
		return
	
	item_picked = item
	
	item_picked_distance = camera.global_position.distance_to(item.global_position)
	
	item_picked.set_picked_up(true)

func drop_item():
	if item_picked == null:
		print('ERROR: Tried to drop a null object')
		return
	
	item_picked.set_picked_up(false)
	
	item_picked = null

# General

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	apply_gravity(delta)
	apply_movement()
	apply_head_bobbing(delta)
	update_object_aimed()
	update_item_picked()

func _input(event): # not sure _unhandled_input() is needed
	if event is InputEventMouseMotion:
		apply_rotation(event)
	elif event.is_action_pressed("pick_up"):
		pick_up_item()
	elif event.is_action_released("pick_up"):
		drop_item()
