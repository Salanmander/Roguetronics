extends Node2D

@onready var floor: FactoryFloor = $FactoryLayer/FactoryFloor
@onready var dispenser_controls: DispenserControls = $UILayer/MachineControls/DispenserControls


# Called when the node enters the scene tree for the first time.
func _ready():
	floor.element_selected.connect(_on_element_selected)
	floor.simulation_started.connect(_on_simulation_started)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func hide_all_controls():
	dispenser_controls.visible = false

func show_control(UIElement: Control):
	UIElement.visible = true
	
func _on_element_selected(element):
	if not element is Dispenser:
		return
	
	dispenser_controls.connect_to(element)
	
	hide_all_controls()
	show_control(dispenser_controls)
	
func _on_simulation_started():
	hide_all_controls()
	

	


