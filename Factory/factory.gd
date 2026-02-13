extends Node2D
class_name Factory

@onready var factory_floor: FactoryFloor = $FactoryLayer/FactoryFloor
@onready var dispenser_control: DispenserControl = $UILayer/MachineControls/DispenserControl
@onready var crane_control: CraneControl = $UILayer/MachineControls/CraneControl
@onready var money_display: Label = $UILayer/MoneyDisplay
@onready var result_screen: ResultScreen = $UILayer/ResultScreen


var projected_money: int
var reward: int
var run_cost: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	
	factory_floor.element_selected.connect(_on_element_selected)
	factory_floor.simulation_started.connect(_on_simulation_started)
	factory_floor.first_cycle_started.connect(_on_first_cycle_started)
	factory_floor.simulation_cycle_end.connect(_on_simulation_cycle_end)
	factory_floor.simulation_reset.connect(_on_simulation_reset)
	factory_floor.won.connect(_on_puzzle_completed)
	
	result_screen.result_accepted.connect(_on_result_accepted)
	result_screen.result_rejected.connect(_on_result_rejected)
	
	
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
			
	
	money_display.text = "$" + str(GameState.money)
	pass # Replace with function body.
	
func _unhandled_input(event: InputEvent):
	var exact_match: bool = true
	if event.is_action_pressed("save", exact_match):
		GameState.save_to_disk.call_deferred()
	if event.is_action_pressed("load", exact_match):
		GameState.load_from_disk.call_deferred()
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass



func change_projected_money(delta: int) -> void:
	projected_money += delta
	money_display.text = "$" + str(projected_money)
	
	
func hide_all_controls():
	dispenser_control.visible = false
	crane_control.visible = false

func show_control(UIElement: Control):
	UIElement.visible = true
	
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	return factory_floor.get_save_dict()
	
func load_from_save_dict(save_dict: Dictionary):
	factory_floor.load_from_save_dict(save_dict)

#endregion
	
func _on_element_selected(element):
	if element is Dispenser:
		dispenser_control.connect_to(element)
		hide_all_controls()
		show_control(dispenser_control)
	
	elif element is Crane:
		crane_control.connect_to(element)
		hide_all_controls()
		show_control(crane_control)
		
func _on_first_cycle_started() -> void:
	projected_money = GameState.money
	
	
func _on_simulation_started():
	hide_all_controls()
	
func _on_simulation_cycle_end() -> void:
	GameState.get_scenario().on_new_cycle(self)
	
	
func _on_simulation_reset() -> void:
	money_display.text = "$" + str(GameState.money)
	
	


func _on_tutorial_button_pressed():
	$TutorialPanel.visible = true
	
func _on_tutorial_closed():
	$TutorialPanel.visible = false
	
	
func _on_puzzle_completed():
	result_screen.set_before(GameState.money)
	result_screen.set_cost(GameState.money - projected_money)
	
	var money_before_reward: int = projected_money
	GameState.get_scenario().on_win(self)
	result_screen.set_reward(projected_money - money_before_reward)
	
	result_screen.set_after(projected_money)
	result_screen.visible = true
	
func _on_result_accepted() ->  void:
	GameState.money = projected_money
	SceneManager.switch_scene(Consts.REWARD)
	
	pass
	
func _on_result_rejected() -> void:
	result_screen.visible = false
	factory_floor.reset_to_start_of_run()
	pass




func _on_win_pressed():
	SceneManager.switch_scene(Consts.REWARD)
