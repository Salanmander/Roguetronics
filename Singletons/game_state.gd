extends Node


var machines_available: Array[MachinePrototype]
var upgrades: UpgradeTree

# 2D array of booleans: true if that space is open on the factory, false
# if not. Size should always be the minimum bounding box needed to contain
# all the open factory space.
var factory_space: Array[Array]

# A start to run-long game mechanics.
var money: int
const starting_money: int = 100
var scenario: Scenario
var scenario_number: int



var save_version: String



func _ready():
	save_version = str(Consts.VERSION_MAJOR)
	save_version += "." + str(Consts.VERSION_MINOR)
	save_version += "." + str(Consts.VERSION_BUILD)
	
	money = starting_money
	upgrades = UpgradeTree.new()
	
	reset_machines()
	
	var upgrade_nodes: Array[Upgrade] = upgrades.get_upgrades_available()
	# TODO: more elegant way to set an initial upgrade
	var upgrades_to_get: Array[Upgrade] = []
	for upgrade:Upgrade in upgrade_nodes:
		if upgrade is NewMachine:
			#print(upgrade.machine_type)
			if upgrade.machine_type == "res://Factory/Machine/Dispenser/dispenser_prototype.gd":
				upgrades_to_get.append(upgrade)
			if upgrade.machine_type == "res://Factory/Machine/Combiner/combiner_prototype.gd":
				upgrades_to_get.append(upgrade)
			if upgrade.machine_type == "res://Factory/Machine/Depot/depot_prototype.gd":
				upgrades_to_get.append(upgrade)
	
	for upgrade: Upgrade in upgrades_to_get:
		add_machine(upgrade)
	
	
	upgrade_nodes = upgrades.get_upgrades_available()
	upgrades_to_get = []
	for upgrade:Upgrade in upgrade_nodes:
		if upgrade is MachineImprovement:
			if upgrade.machine_affected == "DispenserPrototype":
				upgrades_to_get.append(upgrade)
	
	for upgrade: Upgrade in upgrades_to_get:
		improve_machine(upgrade)
		
	var init_factory_width: int = 10
	var init_factory_height: int = 8
	factory_space = []
	factory_space.resize(init_factory_width)
	for x in range(init_factory_width):
		factory_space[x].resize(init_factory_height)
		for y in range(init_factory_height):
			factory_space[x][y] = true
	
	scenario_number = 1
	generate_scenario()
		
func reset_machines() -> void:
	machines_available = []
	machines_available.append(BeltPrototype.new())
				

#region rewards

func get_upgrades_available() -> Array[Upgrade]:
	return upgrades.get_upgrades_available()
	
func get_machines_available() -> Array[MachinePrototype]:
	return machines_available.duplicate()
	
	
	
func add_machine(machine_upgrade: NewMachine, mark_in_tree: bool = true):
	var machine_prototype_path = machine_upgrade.machine_type
	var proto = load(machine_prototype_path)
	machines_available.append(proto.new())
	
	if mark_in_tree:
		upgrades.mark_upgrade_obtained(machine_upgrade)
	
func improve_machine(improvement: MachineImprovement, mark_in_tree: bool = true):
	var machine_class = improvement.machine_affected
	var machine:MachinePrototype
	
	for candidate:MachinePrototype in machines_available:
		if candidate.get_script().get_global_name() == machine_class:
			machine = candidate
	
	if machine:
		machine.call(improvement.machine_callback)
	
	if mark_in_tree:
		upgrades.mark_upgrade_obtained(improvement)

#endregion

func set_money(new_money: int) -> void:
	money = new_money

#region scenarios

func increment_scenario() -> void:
	scenario_number += 1

func get_scenario() -> Scenario:
	return scenario

func generate_scenario() -> void:
	var goal_tier: int = min((scenario_number+2)/2,2) + 1
	var goal: Goal = PuzzleManager.get_goal_from_tier(goal_tier)
	scenario = Scenario.create(goal)
	#var cost: int = int(-1 * scenario_number**(1.7))
	#var cost_per_cycle: Effect = MoneyChange.create(cost)
	#scenario.add_cycle_effect(cost_per_cycle)
	var reward: Effect = MoneyChange.create(10 * goal.get_value())
	scenario.add_win_effect(reward)

#endregion

#region saveAndLoad
# Structure of dictionary that gets saved:
# "factory_space": String for 2D array representing floor tiles of factory
#                  (from var_to_str)
# "scene_index": index of scene into Consts.SCENE_FILES.
#                Used as input to SceneManger.switch_scene
# "scene_data": dictionary given by the top-level scene node. Data will
#               vary with current scene
# "upgrade_tree": dictionary given by the upgrade tree when asked
#                 to save itself. Will be passed back to restore
# "scenario": dictionary given by scenario object. This isn't always
#             in active use, but we sometimes need to track it 
#             between scenes, so it should always exist.
	
func save_to_disk() -> void:
	var save_dict: Dictionary = {}
	var current_scene: Node = get_tree().current_scene
	var current_scene_name: String = current_scene.get_script().get_global_name()
	#print(current_scene_name)
	save_dict["factory_space"] = var_to_str(factory_space)
	save_dict["scene_index"] = Consts.SCENE_FROM_CLASS[current_scene_name]
	save_dict["scene_data"] = current_scene.get_save_dict()
	save_dict["upgrade_tree"] = upgrades.get_save_dict()
	save_dict["scenario"] = scenario.get_save_dict()
	save_dict["version"] = save_version
	
	var save_string: String = JSON.stringify(save_dict)
	var save_file: FileAccess = FileAccess.open(Consts.SAVE_FILENAME, FileAccess.WRITE)
	save_file.store_string(save_string)
	save_file.close()
	pass
	
func load_from_disk() -> void:
	var save_file: FileAccess = FileAccess.open(Consts.SAVE_FILENAME, FileAccess.READ)
	var save_string: String = save_file.get_as_text()
	var save_dict = JSON.parse_string(save_string)
	
	factory_space = str_to_var(save_dict["factory_space"])
	
	scenario = Scenario.create_from_save(save_dict["scenario"])
	
	# Loading in the upgrade tree just marks what upgrades have been gotten or not,
	# it doesn't actually apply them. Need to get the upgrades and apply them
	# here in order for them to take effect.
	upgrades.load_from_dict(save_dict["upgrade_tree"])
	reset_machines()
	var upgrade_nodes: Array[Upgrade] = upgrades.get_upgrades_obtained()
	for upgrade: Upgrade in upgrade_nodes:
		if upgrade is NewMachine:
			add_machine(upgrade, false)
		elif upgrade is MachineImprovement:
			improve_machine(upgrade, false)
	
	
	
	SceneManager.switch_scene(save_dict["scene_index"])
	var current_scene: Node = get_tree().current_scene
	current_scene.load_from_save_dict(save_dict["scene_data"])
	
	pass
	
#endregion
		
