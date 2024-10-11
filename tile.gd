class_name Tile extends StaticBody3D

# Tile
@onready var holding_timer = $Holding
var pressed_by = []
var is_pressed = false

# Animations
@onready var animation_player = $Animator
const animations = {
	'press': 'DOWN',
	'lift': 'UP',
}

func press(value:bool):
	
	if not value:
		animation_player.play("up")
	
	animation_player.play("down")
	# NOTE Tile specific behavior
	# BUG Godot doesnt allow to trigger one shot particles more than 1 time in set lifespan
	# TODO Create a particle spawner function in autoload game.gd, for one shot particles that need to be used multiple times (like here)
	$ActivationParticles.restart()
	$ActivationParticles.emitting = true

func set_is_pressed(value:bool):
	if is_pressed == value: return
	
	var is_pressed_before = is_pressed
	
	if pressed_by.size() != 0:
		
		is_pressed = true
		
		var object_pressing = pressed_by[0]
		
		if object_pressing is Item:
			object_pressing.die(self)
		
		if is_pressed_before == is_pressed:
			print(name, ' press time extended by ', object_pressing.name)
			return
		else:
			print(name, ' pressed by ', object_pressing.name)
	else:
		
		is_pressed = value
		
		print(name, ' pressed' if is_pressed else ' lifted')
	
	if is_pressed:
		animation_player.play(animations.press)
		# NOTE Tile specific behavior
		# BUG Godot doesnt allow to trigger one shot particles more than 1 time in set lifespan
		# TODO Create a particle spawner function in autoload game.gd, for one shot particles that need to be used multiple times (like here)
		$ActivationParticles.restart()
		$ActivationParticles.emitting = true
	else:
		animation_player.play(animations.lift)

func hold_pressed(duration:float, force_overwrite:bool = true):
	if duration < holding_timer.time_left and not force_overwrite: return
	
	add_object_pressing(holding_timer)
	holding_timer.wait_time = duration
	holding_timer.start(0)

func stop_holding():
	$Holding.stop()

func add_object_pressing(object:Object):
	if object == null: return
	if object in pressed_by: return
	if object is Item and object.is_dead: return
	
	pressed_by.append(object)
	set_is_pressed(true)

func remove_object_pressing(object:Object):
	pressed_by.erase(object)
	
	set_is_pressed(false)

func _ready() -> void:
	#set_is_pressed(true)
	#hold_pressed(5.0)
	pass

func _on_detector_body_entered(body:Node3D) -> void:
	add_object_pressing(body)

func _on_detector_body_exited(body:Node3D) -> void:
	remove_object_pressing(body)

func _on_holding_timeout() -> void:
	remove_object_pressing(holding_timer)
