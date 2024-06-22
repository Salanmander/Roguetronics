extends Control
class_name CraneControl

@onready var program: VBoxContainer = $CraneProgram
@onready var bank: VBoxContainer = $CommandBank

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Connect signals from the command slots
	var slots = program.get_children()
	for slot: Panel in slots:
		slot.gui_input.connect(_on_program_slot_input.bind(slot))
		
	slots = bank.get_children()
	for slot: Panel in slots:
		slot.gui_input.connect(_on_bank_slot_input.bind(slot))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func connect_to(crane: Crane):
	pass
	
func _on_program_slot_input(event: InputEvent, slot: Panel):
	if event is InputEventMouseButton:
		if event.is_released() and drag_image.is_holding():
			var focused = get_viewport().gui_get_focus_owner()
			if focused is CommandSlot and focused in program.get_children():
				focused.set_command(drag_image.get_held_item())
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if slot.get_command() != Consts.NO_COMMAND:
				drag_image.hold(slot.get_command())
			slot.set_command(Consts.NO_COMMAND)
	pass
	
func _on_bank_slot_input(event: InputEvent, slot: Panel):
	if event is InputEventMouseButton:
		if event.is_released() and drag_image.is_holding():
			var focused = get_viewport().gui_get_focus_owner()
			if focused is CommandSlot and focused in program.get_children():
				focused.set_command(drag_image.get_held_item())
		elif event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			drag_image.hold(slot.get_command())
	pass
	
	
