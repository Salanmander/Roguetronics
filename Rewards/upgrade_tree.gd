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
	upgrades_unobtained.append(crane_upgrade)
	
	upgrade_type = "res://Factory/Machine/Dispenser/dispenser_prototype.gd"
	upgrade_icon = "res://Factory/Machine/Dispenser/dispenser_widget.png"
	var dispense_upgrade: NewMachine = NewMachine.new(upgrade_type, upgrade_icon)
	upgrades_unobtained.append(dispense_upgrade)
	
	# Upgrade for improving dispenser to add very widget
	var machine_to_upgrade = "DispenserPrototype"
	var upgrade_callback = "enable_very_widget"
	upgrade_icon = "res://Factory/Machine/Dispenser/dispenser_verywidget.png"
	var enable_very_widget: MachineImprovement = MachineImprovement.new(machine_to_upgrade, upgrade_callback, upgrade_icon)
	enable_very_widget.add_requirement(dispense_upgrade)
	upgrades_unobtained.append(enable_very_widget)


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
