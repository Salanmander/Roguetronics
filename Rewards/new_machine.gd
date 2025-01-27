extends Upgrade
class_name NewMachine

var machine_type: String

func _init(machine_type: String = "", icon_path: String = ""):
	self.machine_type = machine_type
	
	button = ButtonPrototype.new()
	button.set_callback("_on_new_machine_upgrade_pressed", [self])
	
	if icon_path:
		button.set_icon(load(icon_path))
	else:
		button.set_text(machine_type)

	pass

func get_machine_type() -> String:
	return machine_type


func matches(other: Upgrade) -> bool:
	if other is not NewMachine:
		return false
	
	return other.machine_type == machine_type
