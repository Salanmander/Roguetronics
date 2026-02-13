extends Resource
class_name Scenario


var goal: Goal

var start_effects: Array[Effect]
var cycle_effects: Array[Effect]
var win_effects: Array[Effect]

func _init() -> void:
	pass
	
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
	

	
