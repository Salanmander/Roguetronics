extends Node2D
class_name Factory

@onready var floor: FactoryFloor = $FactoryLayer/FactoryFloor
@onready var dispenser_control: DispenserControl = $UILayer/MachineControls/DispenserControl
@onready var crane_control: CraneControl = $UILayer/MachineControls/CraneControl

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# TEMP
	GameState.save_to_disk.call_deferred()
	floor.element_selected.connect(_on_element_selected)
	floor.simulation_started.connect(_on_simulation_started)
	floor.won.connect(_on_puzzle_completed)
	
	
	# Create buttons for available machines
	var buttonContainer: GridContainer = $UILayer/ButtonPanel/MachineButtonContainer

	for available: MachinePrototype in GameState.machines_available:
		
		var prototypes: Array[ButtonPrototype] = available.get_button_prototypes()
		
		for proto: ButtonPrototype in prototypes:
			var button: Button = proto.get_button($FactoryLayer/FactoryFloor)
			
			var width: float = buttonContainer.size.x / buttonContainer.columns
			var height: float = buttonContainer.size.y / 2
			button.custom_minimum_size = Vector2(width, height)
			button.expand_icon = true
			buttonContainer.add_child(button)
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
	


func _on_tutorial_button_pressed():
	$TutorialPanel.visible = true
	
func _on_tutorial_closed():
	$TutorialPanel.visible = false
	
	
func _on_puzzle_completed():
	SceneManager.switch_scene(Consts.REWARD)




func _on_win_pressed():
	SceneManager.switch_scene(Consts.REWARD)
