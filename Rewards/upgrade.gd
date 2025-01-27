extends Resource
class_name Upgrade


var requires: Array[Upgrade]


var button: ButtonPrototype


func get_button_prototype() -> ButtonPrototype:
	return button
	
func add_requirement(upgrade: Upgrade) -> void:
	requires.append(upgrade)
	
	
func get_requirements() -> Array[Upgrade]:
	return requires
	
# Checks to see if they're the same upgrade. Must be overridden by sublcasses
func matches(other: Upgrade) -> bool:
	assert(false, "An upgrade class didn't override matches()")
	return false
	
