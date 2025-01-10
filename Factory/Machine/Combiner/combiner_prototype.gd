extends MachinePrototype 
class_name CombinerPrototype



func _init():
	buttons = []
	var button: ButtonPrototype
	
	button = ButtonPrototype.new()
	button.set_callback("_on_place_combiner_pressed")
	button.set_icon(load("res://Factory/Machine/Combiner/combiner_V.png"));
	buttons.append(button)
	
	
	pass
