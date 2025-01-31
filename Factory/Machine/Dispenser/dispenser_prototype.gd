extends MachinePrototype 
class_name DispenserPrototype



func _init():
	buttons = []
	var button: ButtonPrototype
	button = ButtonPrototype.new()
	button.set_callback("_on_place_dispenser_pressed", [1])
	button.set_icon(load("res://Factory/Machine/Dispenser/dispenser_widget.png"));
	buttons.append(button)
	
	pass


func enable_very_widget() -> void:
	
	var button = ButtonPrototype.new()
	button.set_callback("_on_place_dispenser_pressed", [2])
	button.set_icon(load("res://Factory/Machine/Dispenser/dispenser_verywidget.png"));
	buttons.append(button)
