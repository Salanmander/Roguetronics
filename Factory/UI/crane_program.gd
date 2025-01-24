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
		

func get_program() -> Array[int]:
	var program: Array[int] = []
	for slot: CommandSlot in slots:
		program.append(slot.get_command())
		
	for i in range(program.size(), 0, -1):
		if program[i-1] != Consts.NO_COMMAND or i-1 == 0:
			program.resize(i)
			break
		
	return program

# TODO: expanding/decreasing the number of slots is untested
func set_program(program: Array[int]):
	
	for i in range(program.size()):
		var command: int = program[i]
		if i < slots.size():
			slots[i].set_command(command)
		else:
			var new_slot = slot_packed.instantiate()
			slots.append(new_slot)
			add_child(new_slot)
			new_slot.set_command(command)
	
	if program.size() < slots.size():
		for i in range(program.size(), slots.size()):
			slots[i].set_command(Consts.NO_COMMAND)
			
	if program.size() <= num_slots and slots.size() > num_slots:
		for i in range(slots.size(), num_slots, -1):
			slots[i-1].queue_free()
		
		slots.resize(num_slots)
	
		
