extends Resource
class_name UpgradeTree

var upgrades_obtained: Array[int]
var upgrades_unobtained: Array[int]
var all_upgrades: Dictionary


func _init() -> void:
	
	
	var upgrades_file: FileAccess = FileAccess.open(Consts.UPGRADES_FILENAME, FileAccess.READ)
	var upgrades_text: String = upgrades_file.get_as_text()
	var upgrades_dict = JSON.parse_string(upgrades_text)
	
	
	for key: String in upgrades_dict:
		var ID: int = int(key)
		
		var upgrade: Dictionary = upgrades_dict[key]
		var new_upgrade: Upgrade
		if upgrade["type"] == "new":
			var new_machine = upgrade["machine"]
			var icon = upgrade["icon"]
			new_upgrade = NewMachine.new(ID, new_machine, icon)
			
		if upgrade["type"] == "improvement":
			# Upgrade for improving dispenser to add very widget
			var machine_to_upgrade = upgrade["machine"]
			var upgrade_callback = upgrade["callback"]
			var upgrade_icon = upgrade["icon"]
			new_upgrade = MachineImprovement.new(ID, machine_to_upgrade, upgrade_callback, upgrade_icon)
		
		if upgrade.has("requires"):
			var requirements = upgrade["requires"]
			for required_upgrade: int in requirements:
				new_upgrade.add_requirement(required_upgrade)
			
		upgrades_unobtained.append(ID)
		all_upgrades[ID] = new_upgrade


func get_upgrades_available() -> Array[Upgrade]:
	var IDs: Array =  upgrades_unobtained.filter(requirements_met)
	var available: Array[Upgrade] = []
	for ID: int in IDs:
		available.append(all_upgrades[ID])
	return available
	
func get_upgrades_obtained() -> Array[Upgrade]:
	var IDs: Array =  upgrades_obtained
	var available: Array[Upgrade] = []
	for ID: int in IDs:
		available.append(all_upgrades[ID])
	return available
	
func mark_upgrade_obtained(upgrade: Upgrade) -> void:
	upgrades_obtained.append(upgrade.ID)
	upgrades_unobtained = upgrades_unobtained.filter(not_same_as.bind(upgrade.ID))
	pass
	
#region saveAndLoad

# Structure of save dictionary:
#   "obtained" -> Array[int] of upgrades_obtained. Order should be order
#                 they were obtained in.
#   "unobtained" -> Array[int] of upgrades_unobtained
#
#   The upgrade dictionary is not saved, because it shouldn't depend on
#   save game state.

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["obtained"] = var_to_str(upgrades_obtained)
	save_dict["unobtained"] = var_to_str(upgrades_unobtained)
	
	return save_dict
	
func load_from_dict(save_dict: Dictionary) -> void:
	
	# The Array constructor is used to convert the untyped array
	# loaded from JSON into a typed array
	upgrades_obtained = str_to_var(save_dict["obtained"])
	upgrades_unobtained = str_to_var(save_dict["unobtained"])
	return
	

#endregion
	
#region metehods for filters. True means it should *stay in* the list

func requirements_met(upgradeID: int) -> bool:
	var upgrade: Upgrade = all_upgrades[upgradeID]
	var reqs: Array[int] = upgrade.get_requirements()
	for req: int in reqs:
		if not req in upgrades_obtained:
			return false
	return true
	
func not_same_as(upgrade: int, other: int) -> bool:
	return not (upgrade == other)

#endregion
