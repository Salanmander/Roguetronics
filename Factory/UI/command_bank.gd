extends VBoxContainer

var slot_packed = preload("res://Factory/UI/command_slot.tscn")

var slots: Array[CommandSlot]


# Called when the node enters the scene tree for the first time.
func _ready():
	size.y = 100
	
	slots = []
	# Start at 1 to skil the "no command" one
	for i in range(1, Consts.NUM_CRANE_COMMANDS):
		var new_slot = slot_packed.instantiate()
		slots.append(new_slot)
		add_child(new_slot)
		new_slot.set_command(i)
	
		
