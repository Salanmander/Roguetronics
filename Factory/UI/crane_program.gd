extends VBoxContainer

var slot_packed = preload("res://Factory/UI/command_slot.tscn")

const num_slots = 14
var slots: Array[CommandSlot]

# Called when the node enters the scene tree for the first time.
func _ready():
	size.y = 100
	
	slots = []
	for i in range(num_slots):
		var new_slot = slot_packed.instantiate()
		slots.append(new_slot)
		add_child(new_slot)
	
		


