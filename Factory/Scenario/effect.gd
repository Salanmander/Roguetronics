extends Resource
class_name Effect


func _init() -> void:
	pass

static func create_from_save(_save_dict: Dictionary) -> Scenario:
	assert(false, "Effect must implement create_from_save")
	return Scenario.new()

func apply(_factory: Factory) -> void:
	pass
	
func get_save_dict() -> Dictionary:
	assert(false, "Effect must implement get_save_dict")
	return {}
