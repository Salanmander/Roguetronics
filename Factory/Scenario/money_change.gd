extends Effect
class_name MoneyChange

var money_delta: int

#region constructors

static func create(amount: int) -> MoneyChange:
	var new_effect: MoneyChange = MoneyChange.new()
	new_effect.money_delta = amount
	return new_effect

static func create_from_save(save_dict: Dictionary) -> MoneyChange:
	var new_effect: MoneyChange = MoneyChange.new()
	new_effect.load_from_save(save_dict)
	return new_effect

#endregion


func apply(factory: Factory) -> void:
	factory.change_projected_money(money_delta)
	
	
#region saveAndLoad
func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["type"] = "moneyChange"
	save_dict["amount"] = money_delta
	return save_dict
	
func load_from_save(save_dict: Dictionary) -> void:
	money_delta = save_dict["amount"]
	
#endregion
