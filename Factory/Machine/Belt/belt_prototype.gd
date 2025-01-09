extends MachinePrototype 
class_name BeltPrototype



func _init():
	buttons = []
	var button: ButtonPrototype
	button = ButtonPrototype.new()
	button.set_callback("_on_conveyor_select_pressed", [Consts.UP])
	button.set_icon(load("res://Factory/Machine/Belt/Up.png"));
	buttons.append(button)
	
	button = ButtonPrototype.new()
	button.set_callback("_on_conveyor_select_pressed", [Consts.DOWN])
	button.set_icon(load("res://Factory/Machine/Belt/Down.png"));
	buttons.append(button)
	
	
	button = ButtonPrototype.new()
	button.set_callback("_on_conveyor_select_pressed", [Consts.LEFT])
	button.set_icon(load("res://Factory/Machine/Belt/Left.png"));
	buttons.append(button)
	
	
	button = ButtonPrototype.new()
	button.set_callback("_on_conveyor_select_pressed", [Consts.RIGHT])
	button.set_icon(load("res://Factory/Machine/Belt/Right.png"));
	buttons.append(button)
	
	pass
