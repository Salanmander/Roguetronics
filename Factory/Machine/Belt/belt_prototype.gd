extends MachinePrototype 
class_name BeltPrototype



func _init():
	buttons = []
	var leftButton = ButtonPrototype.new()
	leftButton.set_callback("_on_up_conveyor_select_pressed")
	buttons.append(leftButton)
	pass
