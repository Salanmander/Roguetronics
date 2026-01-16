extends Upgrade
class_name MachineImprovement

var machine_affected: String
var machine_callback: String

func _init(ID: int, machine_type: String = "", callback: String = "", icon_path: String = ""):
	machine_affected = machine_type
	machine_callback = callback
	
	self.ID = ID
	
	button = ButtonPrototype.new()
	button.set_callback("_on_machine_improvement_upgrade_pressed", [self])
	
	if icon_path:
		button.set_icon(load(icon_path))
	else:
		button.set_text(machine_affected)

	pass

func get_machine_affected() -> String:
	return machine_affected
	
func get_machine_callback_name() -> String:
	return machine_callback


func matches(other: Upgrade) -> bool:
	if other is not MachineImprovement:
		return false
	
	return (other.machine_affected == machine_affected && other.machine_callback == machine_callback)
