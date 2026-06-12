extends MachinePrototype 
class_name DepotPrototype



func _init():
	buttons = []
	var button: ButtonPrototype
	button = ButtonPrototype.new()
	button.set_callback("_on_place_depot_pressed")
	button.set_icon(load("res://Factory/Machine/Depot/Stripes.png"));
	buttons.append(button)
	
	
	
	pass
