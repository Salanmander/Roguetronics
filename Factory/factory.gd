extends Node2D
class_name Factory

@onready var floor: FactoryFloor = $FactoryLayer/FactoryFloor
@onready var dispenser_control: DispenserControl = $UILayer/MachineControls/DispenserControl
@onready var crane_control: CraneControl = $UILayer/MachineControls/CraneControl

# Called when the node enters the scene tree for the first time.
func _ready():
	floor.element_selected.connect(_on_element_selected)
	floor.simulation_started.connect(_on_simulation_started)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func hide_all_controls():
	dispenser_control.visible = false
	crane_control.visible = false

func show_control(UIElement: Control):
	UIElement.visible = true
	
func _on_element_selected(element):
	var control_to_show: Control = null
	if element is Dispenser:
		dispenser_control.connect_to(element)
		hide_all_controls()
		show_control(dispenser_control)
	
	elif element is Crane:
		crane_control.connect_to(element)
		hide_all_controls()
		show_control(crane_control)
		
	
	
func _on_simulation_started():
	hide_all_controls()
	

	


