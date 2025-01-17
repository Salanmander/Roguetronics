extends Upgrade
class_name NewMachine


func _init(machine_type: String = "", icon_path: String = ""):
	
	button = ButtonPrototype.new()
	button.set_callback("_on_new_machine_upgrade_pressed", [machine_type])
	
	if icon_path:
		button.set_icon(load(icon_path))
	else:
		button.set_text(machine_type)

	pass
	

