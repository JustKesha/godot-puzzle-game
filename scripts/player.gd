class_name Player extends CharacterBody3D

# TODO Add a main menu
# TODO Figure out a way to do checkpoints - game progression saving & loading
# TODO Add saves to the main menu
# TODO Use setget keywords
# NOTE Would probably be better to separate bigger scripts like this one into modules

# Movement
const SPEED = 5.0

# Physics
const GRAVITY = 9.8 # Cannot assign ProjectSettings.get_setting("physics/3d/default_gravity") to a const directly

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
@onready var object_pointer = $Pointer
@onready var pickup_raycast = $Head/Camera/PickupRaycast
@onready var pickup_lock_object = camera
const ITEM_PICKED_SPEED = 7.5
var object_aimed:Object
var item_aimed:Item
var item_picked:Item
var item_picked_distance = 0.0

# Inventory
@onready var inventory_center = $Inventory
# TODO Add the modifiable_number script from that other project to apply on inventory_size, will also be good for HPs
# NOTE Could add dynamic inventory radius based on the number of items (plus min max)
const INVENTORY_ITEM_SPEED = 4.5
# Would also be funny to have an effect that increases the MINIMUM amount of items in inventory.. Kinda like a curse
# ^ Could be implemented with smthn like an inventory updated signal + can_collect_items bool (but not using a system similar to modifiable_numbers mentioned above could result in bugs)
const INVENTORY_SIZE_LIMIT = 7
const INVENTORY_RADIUS = 1.0
const INVENTORY_ADD_FOCUS_RADIUS = .2
const INVENTORY_ROTATION_SPEED_DEFAULT = .25
const INVENTORY_ROTATION_SPEED_FOCUSED = 0.05
const INVENTORY_POSITION_UP = Vector3(0, 1.85, 0)
const INVENTORY_POSITION_DOWN = Vector3(0, 0, 0)
const INVENTORY_FOCUS_ANGLE_UP = 32
const INVENTORY_FOCUS_ANGLE_DOWN = -18
var inventory = []
var is_inventory_displayed = false
var inventory_spin_speed = INVENTORY_ROTATION_SPEED_DEFAULT
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
		if (object_aimed is Item or object_aimed is Tile) and !object_aimed.is_dead:
			object_pointer.point_at(object_aimed)
		else:
			object_pointer.rest()
	elif object_aimed != null:
		object_aimed = null
		object_pointer.rest()
	
	if item_picked != null:
		item_aimed = item_picked
		# Bring back if you want the arrow to point at the picked up item
		# object_pointer.point_at(item_picked)
	elif object_aimed is Item:
		item_aimed = object_aimed 
	elif item_aimed != null:
		item_aimed = null

func get_picked_up_item_lock_position() -> Vector3:
	var lock_object_position = pickup_lock_object.global_position
	var forward = -pickup_lock_object.get_global_transform().basis.z
	return lock_object_position + item_picked_distance * forward

func update_item_picked():
	if item_picked == null: return
	
	item_picked.move_to_position(get_picked_up_item_lock_position(), ITEM_PICKED_SPEED)

func pick_up_item(item:Item = item_aimed):
	if item == null:
		push_warning('Tried to pick up a null item')
		return
	if item.is_dead:
		push_warning('Tried to pick up a dead item')
		return
	if item_picked != null:
		drop_item_picked()
	if item in inventory:
		remove_item(item)
	
	item_picked = item
	item_picked_distance = camera.global_position.distance_to(item.global_position)
	item_picked.set_picked_up(true)
	
	print('Picked up ', item.type)

func drop_item_picked():
	if item_picked == null:
		push_warning('Tried to drop a null object')
		return
	
	print('Dropped ', item_picked.type)
	
	item_picked.set_picked_up(false)
	item_picked.reset_pickup_cd() # To be able to insta collect after drop / use auto-collector
	item_picked = null

# Inventory

func count_inventory_items():
	return inventory.size()

func update_inventory_items():
	if count_inventory_items() == 0: return
	
	# NOTE Consider moving this into an update_inventory_focus func
	
	var is_inventory_focused = false
	var camera_angle = rad_to_deg(get_vertical_rotation())
	
	if is_inventory_displayed:
		if camera_angle <= INVENTORY_FOCUS_ANGLE_DOWN:
			is_inventory_focused = true
	else:
		if camera_angle >= INVENTORY_FOCUS_ANGLE_UP:
			is_inventory_focused = true
	
	var center = inventory_center.global_position
	var radius = INVENTORY_RADIUS + (INVENTORY_ADD_FOCUS_RADIUS if is_inventory_focused else 0)
	var offset = inventory_spin_offset
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
		
		item.move_to_position(pos, INVENTORY_ITEM_SPEED)
	
	inventory_spin_speed = INVENTORY_ROTATION_SPEED_FOCUSED if is_inventory_focused else INVENTORY_ROTATION_SPEED_DEFAULT
	inventory_spin_offset += inventory_spin_speed

func collect_item(item:Item = item_aimed, soft_action:bool = false):
	if item == null: return
	if item in inventory: return
	
	var inv_size = count_inventory_items()
	
	if inv_size >= INVENTORY_SIZE_LIMIT:
		print('Inventory is full ', inv_size, '/', INVENTORY_SIZE_LIMIT)
		# NOTE Could have a specific signal here
		return
	
	# Works like (*LMK* pick -> *E* drop pick collect) if using LMK first, should logically be (*LMK* pick -> *E* collect)
	# Extra drop needed bc third optional argument provided in item.set_picked_up below
	if item == item_picked: drop_item_picked()
	if !item.set_picked_up(true, soft_action, false): return
	
	inventory.append(item)
	
	print('Collected ', item.type)
	print('Inventory: ', ', '.join(inventory.map(func(i): return i.type)), ' (' + str(inventory.size()), '/', INVENTORY_SIZE_LIMIT, ')')

func remove_item(item:Item = item_aimed, soft_action:bool = false):
	if item == null: return
	if not item in inventory: return
	if !item.set_picked_up(false, soft_action): return
	
	inventory.erase(item)
	
	print('Removed ', item.type, ' from inventory')
	if inventory.size() > 0:
		print('Inventory: ', ', '.join(inventory.map(func(i): return i.type)), ' (' + str(inventory.size()), '/', INVENTORY_SIZE_LIMIT, ')')

# Inventory - display

# NOTE Not used atm
func show_inventory(value:bool):
	for item in inventory:
		item.visible = value
		item.set_hitbox_disabled(!value)

func set_inventory_displayed(value:bool):
	is_inventory_displayed = value
	
	if is_inventory_displayed:
		inventory_center.position = INVENTORY_POSITION_DOWN
		# show_inventory(true)
	else:
		inventory_center.position = INVENTORY_POSITION_UP
		# show_inventory(false)

# Inventory - auto collect

# WARNING Only items that have been recently picked up by the player should be detectable by this area
# This could be fixed by having a delay timer and a bool var on each item, but isnt necesarry as theres probably
# not gonna be a scenario in game where this can accour
func _on_auto_collect_body_entered(body:Node3D):
	if not body is Item: return
	if body in inventory: return
	
	collect_item(body, true)

# General

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_inventory_displayed(false)

func _physics_process(delta):
	apply_gravity(delta)
	apply_movement()
	apply_head_bobbing(delta)
	update_object_aimed()
	update_item_picked()
	update_inventory_items()

func _input(event): # not sure _unhandled_input() is needed
	if event is InputEventMouseMotion:
		apply_rotation(event)
	
	elif event.is_action_pressed("pick_up"):
		pick_up_item()
	elif event.is_action_released("pick_up"):
		drop_item_picked()
	
	elif event.is_action_released("collect"):
		if item_aimed in inventory:
			remove_item(item_aimed, true)
		else:
			collect_item(item_aimed, true)
	
	elif event.is_action_pressed("inventory"):
		set_inventory_displayed(true)
	elif event.is_action_released("inventory"):
		set_inventory_displayed(false)

	elif event.is_action_pressed("inventory_toggle"):
		set_inventory_displayed(!is_inventory_displayed)

	elif event.is_action_pressed("go_to_menu"):
		Global.goto_menu()
