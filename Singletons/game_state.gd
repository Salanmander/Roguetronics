extends Node


var machines_available: Array[MachinePrototype]

# make a MachinePrototype class
# Prototype holds all the information necessary to know a machine's powers
# subclasses for each machine maybe?
# available_machines is array of MachinePrototypes
# make button(s) for each MachinePrototype


func _ready():
	machines_available.append(BeltPrototype.new())

