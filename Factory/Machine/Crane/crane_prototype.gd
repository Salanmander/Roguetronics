extends MachinePrototype 
class_name CranePrototype



func _init():
	buttons = []
	var button: ButtonPrototype
	button = ButtonPrototype.new()
	button.set_callback("_on_place_track_pressed")
	button.set_text("Place\nTrack");
	buttons.append(button)
	
	
	button = ButtonPrototype.new()
	button.set_callback("_on_place_crane_pressed")
	button.set_text("Crane");
	buttons.append(button)
	
	
	pass
