extends Resource
class_name Effect


func _init() -> void:
	pass

static func create_from_save(save_dict: Dictionary) -> Effect:
	if(save_dict["type"] == "moneyChange"):
		return MoneyChange.create_from_save(save_dict)
		
	assert(false, "Attempted to load invalid type of effect")
	return Effect.new()

func apply(_factory: Factory) -> void:
	pass
	
func get_save_dict() -> Dictionary:
	assert(false, "Effect must implement get_save_dict")
	return {}
