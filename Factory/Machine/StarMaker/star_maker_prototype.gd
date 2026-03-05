extends MachinePrototype 
class_name StarMakerPrototype



func _init():
	buttons = []
	var button: ButtonPrototype
	button = ButtonPrototype.new()
	button.set_callback("_on_place_star_pressed", [])
	button.set_icon(load("res://Factory/Machine/StarMaker/StarMaker.png"));
	buttons.append(button)
	
	pass
	
