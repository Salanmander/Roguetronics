extends Resource
class_name UpgradeTree

var upgrades_obtained: Array[Upgrade]
var upgrades_unobtained: Array[Upgrade]


func _init() -> void:
	
	var upgrade_type = "res://Factory/Machine/Combiner/combiner_prototype.gd"
	var upgrade_icon = "res://Factory/Machine/Combiner/combiner_H.png"
	var combine_upgrade: NewMachine = NewMachine.new(upgrade_type, upgrade_icon)
	upgrades_unobtained.append(combine_upgrade)
	
	upgrade_type = "res://Factory/Machine/Crane/crane_prototype.gd"
	var crane_upgrade: NewMachine = NewMachine.new(upgrade_type)
	crane_upgrade.add_requirement(combine_upgrade)
	upgrades_unobtained.append(crane_upgrade)


func get_upgrades_available() -> Array[Upgrade]:
	return upgrades_unobtained.filter(requirements_met)
	
func mark_upgrade_obtained(upgrade: Upgrade) -> void:
	upgrades_obtained.append(upgrade)
	upgrades_unobtained = upgrades_unobtained.filter(not_same_as.bind(upgrade))
	pass
	
#region metehods for filters. True means it should *stay in* the list

func requirements_met(upgrade: Upgrade) -> bool:
	var reqs: Array[Upgrade] = upgrade.get_requirements()
	for req: Upgrade in reqs:
		if not req in upgrades_obtained:
			return false
	return true
	
func not_same_as(upgrade: Upgrade, other: Upgrade) -> bool:
	return not (upgrade == other)

#endregion
