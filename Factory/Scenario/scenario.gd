extends Resource
class_name Scenario


var goal: Goal

var start_effects: Array[Effect]
var cycle_effects: Array[Effect]
var win_effects: Array[Effect]

func _init() -> void:
	pass
	
static func create_from_save(save_dict: Dictionary):
	var new_scenario: Scenario = Scenario.new()
	new_scenario.load_from_save(save_dict)
	return new_scenario
	
	
static func create(goal: Goal) -> Scenario:
	var new_scenario: Scenario = Scenario.new()
	new_scenario.goal = goal
	return new_scenario
	
func add_goal(new_goal: Goal) -> void:
	goal = new_goal.copy()
	
func get_goals() -> Array[Goal]:
	return [goal]

func add_start_effect(new_effect: Effect) -> void:
	start_effects.append(new_effect)
	
func add_cycle_effect(new_effect: Effect) -> void:
	cycle_effects.append(new_effect)
	
func add_win_effect(new_effect: Effect) -> void:
	win_effects.append(new_effect)



func on_start(factory: Factory) -> void:
	for effect: Effect in start_effects:
		effect.apply(factory)
		
func on_new_cycle(factory: Factory) -> void:
	for effect: Effect in cycle_effects:
		effect.apply(factory)
		
func on_win(factory: Factory) -> void:
	for effect: Effect in win_effects:
		effect.apply(factory)
		
		
func get_cycle_delta() -> int:
	var cycle_delta: int = 0
	for effect: Effect in cycle_effects:
		if effect is MoneyChange:
			cycle_delta += effect.money_delta
	
	return cycle_delta
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["goal"] = goal.get_save_dict()
	
	var start_effect_save: Array[Dictionary] = []
	for effect: Effect in start_effects:
		start_effect_save.append(effect.get_save_dict())
	save_dict["start"] = start_effect_save
	
	var cycle_effect_save: Array[Dictionary] = []
	for effect: Effect in cycle_effects:
		cycle_effect_save.append(effect.get_save_dict())
	save_dict["cycle"] = cycle_effect_save
		
	var win_effect_save: Array[Dictionary] = []
	for effect: Effect in win_effects:
		win_effect_save.append(effect.get_save_dict())
	save_dict["win"] = win_effect_save
	
	return save_dict
	
func load_from_save(save_dict: Dictionary):
	goal = Goal.create_from_save(save_dict["goal"])
	
	for effect_dict: Dictionary in save_dict["start"]:
		add_start_effect(Effect.create_from_save(effect_dict))
		
	for effect_dict: Dictionary in save_dict["cycle"]:
		add_cycle_effect(Effect.create_from_save(effect_dict))
		
	for effect_dict: Dictionary in save_dict["win"]:
		add_win_effect(Effect.create_from_save(effect_dict))
		
	pass
	

#endregion
			
	

	
