extends Button



func other_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		set_pressed_no_signal(false)
