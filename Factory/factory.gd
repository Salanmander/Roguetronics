extends Node2D
class_name Factory

@onready var dispenser_control: DispenserControl = $UILayer/MachineControls/DispenserControl
@onready var crane_control: CraneControl = $UILayer/MachineControls/CraneControl
@onready var money_display: Label = $UILayer/MoneyDisplay
@onready var cycle_cost_display: Label = $UILayer/CycleCostDisplay
@onready var base_value_display: Label = $UILayer/BaseValueDisplay
@onready var result_screen: ResultScreen = $UILayer/ResultScreen

var factory_floors: Array[FactoryFloor]
var active_floor_ind: int
var factory_view_size: Vector2i

var projected_money: int
var reward: int
var during_run_costs: int
var during_run_income: int

# Called when the node enters the scene tree for the first time.
func _ready():
	factory_floors = []
	
	var active_floor: FactoryFloor = FactoryFloor.create()
	factory_floors.append(active_floor)
	active_floor_ind = 0
	$FactoryLayer.add_child(active_floor)
	
	connect_floor_signals()
	connect_buttons_to_floor()
	
	result_screen.result_accepted.connect(_on_result_accepted)
	result_screen.result_rejected.connect(_on_result_rejected)
	
	
	# Create buttons for available machines
	var buttonContainer: GridContainer = $UILayer/ButtonPanel/MachineButtonContainer

	for available: MachinePrototype in GameState.machines_available:
		
		var prototypes: Array[ButtonPrototype] = available.get_button_prototypes()
		
		for proto: ButtonPrototype in prototypes:
			var button: Button = proto.get_button(active_floor)
			
			var width: float = buttonContainer.size.x / buttonContainer.columns
			var height: float = buttonContainer.size.y / 2
			button.custom_minimum_size = Vector2(width, height)
			button.expand_icon = true
			buttonContainer.add_child(button)
			
	
	money_display.text = "$" + str(GameState.money)
	
	
	var cycle_delta: int = GameState.get_scenario().get_cycle_delta()
	var sign_str: String = "-"
	if cycle_delta > 0:
		sign_str = "+"
	elif cycle_delta == 0:
		sign_str = ""
	cycle_cost_display.text = sign_str + "$" + str(abs(cycle_delta)) + " per cycle"
	
	var value: int = GameState.get_scenario().get_goals()[0].get_value()
	base_value_display.text = "Goal value: $" + str(value)
	
	# Make factory floor scale its size appropriately.
	# Get viewport x/y size
	var floor_view_x: int = get_window().size.x
	floor_view_x -= $UILayer/MachineControls.size.x
	var floor_view_y: int = get_window().size.y
	floor_view_y -= $UILayer/ButtonPanel.size.y
	floor_view_y -= $UILayer/FloorSelectorPanel.size.y
	set_factory_view_size(Vector2i(floor_view_x, floor_view_y))
	rescale_factory()

func connect_floor_signals() -> void:
	var active_floor: FactoryFloor = factory_floors[active_floor_ind]
	
	active_floor.element_selected.connect(_on_element_selected)
	active_floor.simulation_started.connect(_on_simulation_started)
	active_floor.first_cycle_started.connect(_on_first_cycle_started)
	active_floor.simulation_cycle_end.connect(_on_simulation_cycle_end)
	active_floor.simulation_reset.connect(_on_simulation_reset)
	active_floor.assembly_sent.connect(_on_assembly_sent)
	active_floor.won.connect(_on_puzzle_completed)

func connect_buttons_to_floor() -> void:
	var active_floor: FactoryFloor = factory_floors[active_floor_ind]
	
	var buttons: Panel = $UILayer/ButtonPanel
	buttons.get_node("Run").pressed.connect(active_floor._on_run_pressed)
	buttons.get_node("Pause").pressed.connect(active_floor._on_pause_pressed)
	buttons.get_node("Reset").pressed.connect(active_floor._on_reset_pressed)
	buttons.get_node("Clear").pressed.connect(active_floor._on_clear_pressed)
	buttons.get_node("NewPuzzle").pressed.connect(active_floor._on_new_puzzle_pressed)
	buttons.get_node("Delete").pressed.connect(active_floor._on_delete_pressed)
	buttons.get_node("SpeedX2").pressed.connect(active_floor._on_fast_pressed.bind(2))
	buttons.get_node("SpeedX10").pressed.connect(active_floor._on_fast_pressed.bind(10))


#region screen scaling

func set_factory_view_size(size: Vector2i) -> void:
	factory_view_size = size
	
func rescale_factory() -> void:
	var x_tiles: int = GameState.factory_space.size()
	var y_tiles: int = GameState.factory_space[0].size()
	
	var x_factory_pixels: int = int((x_tiles) * Consts.GRID_SIZE)
	var y_factory_pixels: int = int((y_tiles) * Consts.GRID_SIZE)
	var buffer_pixels: int = int(2*Consts.GRID_SIZE)
	
	var x_max_scale = factory_view_size.x/float(x_factory_pixels + buffer_pixels)
	var y_max_scale = factory_view_size.y/float(y_factory_pixels + buffer_pixels)
	
	$FactoryLayer.scale = Vector2(1, 1) * min(x_max_scale, y_max_scale)
	
	var extra_pixels_x: int = factory_view_size.x - int(x_factory_pixels*$FactoryLayer.scale.x)
	var extra_pixels_y: int = factory_view_size.y - int(y_factory_pixels*$FactoryLayer.scale.y)
	$FactoryLayer.offset.x = (extra_pixels_x)/2
	$FactoryLayer.offset.y = (extra_pixels_y)/2
	

#endregion

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
	if delta < 0:
		during_run_costs -= delta
	else:
		during_run_income += delta
		
	if projected_money < 0:
		factory_floors[active_floor_ind].crash()
		pass
	
	
func hide_all_controls():
	dispenser_control.visible = false
	crane_control.visible = false

func show_control(UIElement: Control):
	UIElement.visible = true
	
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	return factory_floors[active_floor_ind].get_save_dict()
	
func load_from_save_dict(save_dict: Dictionary):
	factory_floors[active_floor_ind].load_from_save_dict(save_dict)

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
	during_run_costs = 0
	during_run_income = 0
	
	
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
	
	
# TODO: do I want to handle this with a scenario effect rather
# than hard-coding it?
func _on_assembly_sent(sent: Assembly) -> void:
	change_projected_money(sent.get_value())
	
	
func _on_puzzle_completed():
	result_screen.set_before(GameState.money)
	result_screen.set_cost(during_run_costs)
	result_screen.set_income(during_run_income)
	
	var money_before_reward: int = projected_money
	GameState.get_scenario().on_win(self) 
	result_screen.set_reward(projected_money - money_before_reward)
	
	result_screen.set_after(projected_money)
	result_screen.visible = true
	
func _on_result_accepted() ->  void:
	GameState.set_money(projected_money)
	GameState.increment_scenario()
	SceneManager.switch_scene(Consts.REWARD)
	
	pass
	
func _on_result_rejected() -> void:
	result_screen.visible = false
	factory_floors[active_floor_ind].reset_to_start_of_run()
	pass


func _on_win_pressed():
	_on_first_cycle_started()
	_on_puzzle_completed()
