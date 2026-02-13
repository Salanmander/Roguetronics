extends Effect
class_name MoneyChange

var money_delta: int


static func create(amount: int) -> MoneyChange:
	var new_effect: MoneyChange = MoneyChange.new()
	new_effect.money_delta = amount
	return new_effect


func apply(factory: Factory) -> void:
	factory.change_projected_money(money_delta)
