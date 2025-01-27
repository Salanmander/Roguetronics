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
	machines_available.append(DispenserPrototype.new())
	
	upgrades = UpgradeTree.new()
	
func get_upgrades_available():
	return upgrades.get_upgrades_available()
	
	
	
func add_machine(machine_upgrade: NewMachine):
	var machine_prototype_path = machine_upgrade.machine_type
	var proto = load(machine_prototype_path)
	machines_available.append(proto.new())
	
	upgrades.mark_upgrade_obtained(machine_upgrade)
	

		
