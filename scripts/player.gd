class_name Player extends CharacterBody3D

# TODO Add proper functions for HITPOINT, temporary at least

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
var item_aimed:Item
var item_picked:Item
var item_picked_distance = 0.0

# Inventory
@onready var inventory_center = $Inventory
# TODO Add dynamic inventory radius (plus max and min radius)
const INVENTORY_RADIUS = 1.0
const INVENTORY_FOCUS_ANGLE_X = 20
const INVENTORY_SPEED_DEFAULT = .35
const INVENTORY_SPEED_FOCUSED = .05
const INVENTORY_POSITION_UP = Vector3(0, 1.75, 0)
const INVENTORY_POSITION_DOWN = Vector3(0, 0, 0)
var inventory = []
var is_inventory_displayed = false
var inventory_spin_speed = INVENTORY_SPEED_DEFAULT
var inventory_spin_offset = 0.0

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

func get_vertical_rotation() -> float:
	return camera.rotation.x

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

# TODO Rename, technically now updates object_aimed and item_aimed
func update_object_aimed():
	if pickup_raycast.is_colliding():
		object_aimed = pickup_raycast.get_collider()
		# WARNING Temporary code
		$HITPOINT/Animator.play("POINT")
		$HITPOINT.global_position = object_aimed.global_position + Vector3(0, 1.2, 0)
	else:
		object_aimed = null
		$HITPOINT.global_position = Vector3(0, -10, 0)
	
	if item_picked != null:
		item_aimed = item_picked
		# WARNING Temporary code
		$HITPOINT/Animator.play("POINT")
		$HITPOINT.global_position = item_picked.global_position + Vector3(0, 1.2, 0)
	elif object_aimed is Item:
		item_aimed = object_aimed 
	else:
		item_aimed = null

func get_picked_up_item_lock_position() -> Vector3:
	var lock_object_position = pickup_lock_object.global_position
	var forward = -pickup_lock_object.get_global_transform().basis.z
	return lock_object_position + item_picked_distance * forward

func update_item_picked():
	if item_picked == null: return
	
	item_picked.move_to_position(get_picked_up_item_lock_position())

func pick_up_item(item:Item = item_aimed):
	if item == null:
		print('ERROR: Tried to pick up a null item')
		return
	if item.is_dead:
		print('ERROR: Tried to pick up a dead item')
		return
	if item_picked != null:
		drop_item_picked()
	if item in inventory:
		remove_item(item)
	
	item_picked = item
	item_picked_distance = camera.global_position.distance_to(item.global_position)
	item_picked.set_picked_up(true)
	
	print('Picked up ', item.name)

func drop_item_picked():
	if item_picked == null:
		print('ERROR: Tried to drop a null object')
		return
	
	print('Dropped ', item_picked.name)
	
	item_picked.set_picked_up(false)
	item_picked = null

# Inventory

func update_inventory_items():
	if inventory.size() == 0: return
	
	var center = inventory_center.global_position
	var radius = INVENTORY_RADIUS
	var offset = inventory_spin_offset
	var index  = 0
	# WARNING Careful, angles.size doesnt always equal to inventory.size;
	# Godot range func transforms all args into int (will result in more arguments than expected if inventory.size is equal to 7 or 11)
	var angles = range(0, 360, 360 / inventory.size())
	
	for i in range(inventory.size()):
		var item = inventory[i]
		var pos  = Vector3(
			center.x + radius * cos(deg_to_rad(angles[i] + offset)),
			center.y,
			center.z + radius * sin(deg_to_rad(angles[i] + offset))
		)
		
		item.move_to_position(pos)
	
	# Could put this in apply_rotation, but there would be no difference
	inventory_spin_speed = INVENTORY_SPEED_FOCUSED if rad_to_deg(get_vertical_rotation()) >= INVENTORY_FOCUS_ANGLE_X else INVENTORY_SPEED_DEFAULT
	inventory_spin_offset += inventory_spin_speed

func collect_item(item:Item = item_aimed):
	if item == null:
		print('ERROR: Tried to collect a null item')
		return
	if item in inventory:
		print('ERROR: Tried to collect an item already in inventory')
		return
	# TODO Dont like console spam with drop pick collect, should be collect / pick collect
	if item == item_picked:
		drop_item_picked()
	
	item.set_picked_up(true, false)
	
	inventory.append(item)
	
	print('Collected ', item.name)
	print('Inventory: ' + ', '.join(inventory.map(func(i): return i.name)) + ' (' + str(inventory.size()) + ')')

# TODO Consider a name change
func remove_item(item:Item = item_aimed):
	if item == null:
		print('ERROR: Tried to remove a null item')
		return
	if not item in inventory:
		print('ERROR: Tried to remove an item that is not in inventory')
		return
	
	item.set_picked_up(false)
	inventory.erase(item)
	
	print('Removed ', item.name, ' from inventory')
	if inventory.size() > 0:
		print('Inventory: ' + ', '.join(inventory.map(func(i): return i.name)) + ' (' + str(inventory.size()) + ')')

# Inventory display

# NOTE Function not used anymore
func show_inventory(value:bool):
	for item in inventory:
		item.visible = value
		item.set_hitbox_disabled(!value)

func set_inventory_dispaly(value:bool):
	is_inventory_displayed = value
	
	if is_inventory_displayed:
		inventory_center.position = INVENTORY_POSITION_DOWN
		# show_inventory(true)
	else:
		inventory_center.position = INVENTORY_POSITION_UP
		# show_inventory(false)

# General

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_inventory_dispaly(false)

func _physics_process(delta):
	apply_gravity(delta)
	apply_movement()
	apply_head_bobbing(delta)
	update_object_aimed()
	update_item_picked()
	update_inventory_items()

func _on_auto_collect_body_entered(body:Node3D):
	if not body is Item: return
	if body in inventory: return
	
	collect_item(body)

func _input(event): # not sure _unhandled_input() is needed
	if event is InputEventMouseMotion:
		apply_rotation(event)
	
	elif event.is_action_pressed("pick_up"):
		pick_up_item()
	elif event.is_action_released("pick_up"):
		drop_item_picked()
	
	elif event.is_action_released("collect"):
		if item_aimed in inventory:
			remove_item()
		else:
			collect_item()
	
	elif event.is_action_pressed("inventory"):
		set_inventory_dispaly(true)
	elif event.is_action_released("inventory"):
		set_inventory_dispaly(false)

	elif event.is_action_pressed("inventory_toggle"):
		set_inventory_dispaly(!is_inventory_displayed)
