extends Node


var machines_available: Array[MachinePrototype]
var upgrades: UpgradeTree

# make a MachinePrototype class
# Prototype holds all the information necessary to know a machine's powers
# subclasses for each machine maybe?
# available_machines is array of MachinePrototypes
# make button(s) for each MachinePrototype


func _ready():
	machines_available.append(BeltPrototype.new())
	
	upgrades = UpgradeTree.new()
	
	var upgrade_nodes: Array[Upgrade] = upgrades.get_upgrades_available()
	
	# TODO: more elegant way to set an initial upgrade
	var upgrade_to_get: Upgrade = null
	for upgrade:Upgrade in upgrade_nodes:
		if upgrade is NewMachine:
			print(upgrade.machine_type)
			if upgrade.machine_type == "res://Factory/Machine/Dispenser/dispenser_prototype.gd":
				upgrade_to_get = upgrade
	
	if(upgrade_to_get):
		add_machine(upgrade_to_get)
				
	
func get_upgrades_available():
	return upgrades.get_upgrades_available()
	
func get_machines_available():
	return machines_available.duplicate()
	
	
	
func add_machine(machine_upgrade: NewMachine):
	var machine_prototype_path = machine_upgrade.machine_type
	var proto = load(machine_prototype_path)
	machines_available.append(proto.new())
	
	upgrades.mark_upgrade_obtained(machine_upgrade)
	
func improve_machine(improvement: MachineImprovement):
	var machine_class = improvement.machine_affected
	var machine:MachinePrototype
	
	for candidate:MachinePrototype in machines_available:
		if candidate.get_script().get_global_name() == machine_class:
			machine = candidate
	
	if machine:
		machine.call(improvement.machine_callback)
	
	upgrades.mark_upgrade_obtained(improvement)
	
# Structure of dictionary that gets saved:
# "scene_index": index of scene into Consts.SCENE_FILES.
#                Used as input to SceneManger.switch_scene
	
func save_to_disk() -> void:
	var save_dict: Dictionary = {}
	var current_scene_name: String = get_tree().current_scene.get_script().get_global_name()
	print(current_scene_name)
	save_dict["scene_index"] = Consts.SCENE_FROM_CLASS[current_scene_name]
	
	var save_string: String = JSON.stringify(save_dict)
	var save_file: FileAccess = FileAccess.open(Consts.SAVE_FILENAME, FileAccess.WRITE)
	save_file.store_string(save_string)
	save_file.close()
	pass
	
func load_from_disk() -> void:
	var save_file: FileAccess = FileAccess.open(Consts.SAVE_FILENAME, FileAccess.READ)
	var save_string: String = save_file.get_as_text()
	var save_dict = JSON.parse_string(save_string)
	
	SceneManager.switch_scene(save_dict["scene_index"])
	
	pass
	

		
