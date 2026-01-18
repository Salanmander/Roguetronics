extends Node


var machines_available: Array[MachinePrototype]
var upgrades: UpgradeTree



func _ready():
	
	upgrades = UpgradeTree.new()
	
	reset_machines()
	
	var upgrade_nodes: Array[Upgrade] = upgrades.get_upgrades_available()
	# TODO: more elegant way to set an initial upgrade
	var upgrade_to_get: Upgrade = null
	for upgrade:Upgrade in upgrade_nodes:
		if upgrade is NewMachine:
			#print(upgrade.machine_type)
			if upgrade.machine_type == "res://Factory/Machine/Dispenser/dispenser_prototype.gd":
				upgrade_to_get = upgrade
	
	if(upgrade_to_get):
		add_machine(upgrade_to_get)
		
func reset_machines() -> void:
	machines_available = []
	machines_available.append(BeltPrototype.new())
				
	
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
	
# Structure of dictionary that gets saved:
# "scene_index": index of scene into Consts.SCENE_FILES.
#                Used as input to SceneManger.switch_scene
# "scene_data": dictionary given by the top-level scene node. Data will
#               vary with current scene
# "upgrade_tree": dictionary given by the upgrade tree when asked
#                 to save itself. Will be passed back to restore
	
func save_to_disk() -> void:
	var save_dict: Dictionary = {}
	var current_scene: Node = get_tree().current_scene
	var current_scene_name: String = current_scene.get_script().get_global_name()
	#print(current_scene_name)
	save_dict["scene_index"] = Consts.SCENE_FROM_CLASS[current_scene_name]
	save_dict["scene_data"] = current_scene.get_save_dict()
	save_dict["upgrade_tree"] = upgrades.get_save_dict()
	
	var save_string: String = JSON.stringify(save_dict)
	var save_file: FileAccess = FileAccess.open(Consts.SAVE_FILENAME, FileAccess.WRITE)
	save_file.store_string(save_string)
	save_file.close()
	pass
	
func load_from_disk() -> void:
	var save_file: FileAccess = FileAccess.open(Consts.SAVE_FILENAME, FileAccess.READ)
	var save_string: String = save_file.get_as_text()
	var save_dict = JSON.parse_string(save_string)
	
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
	

		
