extends Node


var machines_available: Array[MachinePrototype]
var upgrades_available: Array[Upgrade]

# make a MachinePrototype class
# Prototype holds all the information necessary to know a machine's powers
# subclasses for each machine maybe?
# available_machines is array of MachinePrototypes
# make button(s) for each MachinePrototype


func _ready():
	machines_available.append(BeltPrototype.new())
	machines_available.append(DispenserPrototype.new())
	
	var upgrade_type = "res://Factory/Machine/Combiner/combiner_prototype.gd"
	var upgrade_icon = "res://Factory/Machine/Combiner/combiner_H.png"
	upgrades_available.append(NewMachine.new(upgrade_type, upgrade_icon))
	
	upgrade_type = "res://Factory/Machine/Crane/crane_prototype.gd"
	upgrades_available.append(NewMachine.new(upgrade_type))
	
	
func add_machine(machine_prototype_path: String):
	var proto = load(machine_prototype_path)
	machines_available.append(proto.new())
	
	# Filter to get only the upgrades that *aren't* the upgrade we just
	# got
	# TODO: Replace with data structure for keeping track of all
	# upgrades
	upgrades_available = upgrades_available.filter(\
		func(upgrade: Upgrade): \
			return not( (upgrade is NewMachine) and (upgrade.get_machine_type() == machine_prototype_path) )\
		)
	pass
	

		
