extends CanvasLayer

func _on_button_new_pressed() -> void:
	Global.start_demo()
	
func _on_button_continue_pressed() -> void:
	Global.start_demo_from_save_file()

func _on_button_exit_pressed() -> void:
	Global.close_game()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print('Main menu')
