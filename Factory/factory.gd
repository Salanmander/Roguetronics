extends Node2D
class_name Factory

@onready var dispenser_control: DispenserControl = $UILayer/MachineControls/DispenserControl
@onready var crane_control: CraneControl = $UILayer/MachineControls/CraneControl
@onready var depot_control: DepotControl = $UILayer/MachineControls/DepotControl
@onready var money_display: Label = $UILayer/MoneyDisplay
@onready var cycle_cost_display: Label = $UILayer/CycleCostDisplay
@onready var base_value_display: Label = $UILayer/BaseValueDisplay
@onready var result_screen: ResultScreen = $UILayer/ResultScreen
@onready var layout_select_row = $UILayer/FloorSelectorPanel/HBoxContainer

var factory_layouts: Array[FactoryFloor] = []
var active_layout_ind: int
var factory_view_size: Vector2i

var click_mode: int = Consts.NONE
var conveyor_direction: float = 0
var widget_type: int = 0
var goal_index: int = 0

var crashed: bool = false
var running: bool = false
var whole_factory_running: bool = false

var projected_money: int
var reward: int
var during_run_costs: int
var during_run_income: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	new_layout()
	
	
	result_screen.result_accepted.connect(_on_result_accepted)
	result_screen.result_rejected.connect(_on_result_rejected)
	
	
	# Create buttons for goals
	var buttonContainer: GridContainer = $UILayer/ButtonPanel/MachineButtonContainer
	for i in range(GameState.get_scenario().get_goals().size()):
		var button: Button = Button.new()
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.text = "Goal " + str(i)
		button.pressed.connect(_on_place_goal_pressed.bind(i))
	
		var width: float = buttonContainer.size.x / buttonContainer.columns
		var height: float = buttonContainer.size.y / 2
		button.custom_minimum_size = Vector2(width, height)
		buttonContainer.add_child(button)
		

	# Create buttons for available machines
	for available: MachinePrototype in GameState.machines_available:
		
		var prototypes: Array[ButtonPrototype] = available.get_button_prototypes()
		
		for proto: ButtonPrototype in prototypes:
			var button: Button = proto.get_button(self)
			
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

#region floor layout managing

func new_layout() -> void:
	var new_layout: FactoryFloor = FactoryFloor.create()
	var new_ind: int = add_layout(new_layout)
	switch_to_layout(new_ind)
	

# Return value is the index of the added layout
func add_layout(new_layout: FactoryFloor) -> int:
	factory_layouts.append(new_layout)
	$FactoryLayer.add_child(new_layout)
	var new_ind: int = factory_layouts.size() - 1
	connect_floor_signals(new_ind)
	
	# Make button to select that floor
	var floor_button: Button = Button.new()
	floor_button.action_mode =BaseButton.ACTION_MODE_BUTTON_PRESS
	floor_button.pressed.connect(switch_to_layout_of_button.bind(floor_button))
	
	layout_select_row.add_child(floor_button)
	var add_button = $UILayer/FloorSelectorPanel/HBoxContainer/AddFactoryLayout
	layout_select_row.move_child(add_button, -1)
	update_floor_thumbnail(new_ind)
	
	if(factory_layouts.size() > 1):
		$UILayer/FloorSelectorPanel/DeleteLayout.set_disabled(false)
	
	return new_ind
	
func remove_layout_at(index: int) -> void:
	$FactoryLayer.remove_child(factory_layouts[index])
	factory_layouts[index].queue_free()
	factory_layouts.remove_at(index)
	
	var select_buttons: Array[Node] = layout_select_row.get_children()
	select_buttons[index].queue_free()
	layout_select_row.remove_child(select_buttons[index])
	
	
	if(index > 0):
		switch_to_layout(index - 1)
	else:
		switch_to_layout(0)
	
	if(factory_layouts.size() <= 1):
		$UILayer/FloorSelectorPanel/DeleteLayout.set_disabled(true)
	

func connect_floor_signals(index: int) -> void:
	var layout: FactoryFloor = factory_layouts[index]
	
	layout.floor_changed.connect(_on_floor_modified.bind(layout))
	layout.element_selected.connect(_on_element_selected)
	layout.simulation_cycle_end.connect(_on_simulation_cycle_end)
	layout.simulation_reset.connect(_on_simulation_reset)
	layout.assembly_sent.connect(_on_assembly_sent)
	layout.won.connect(_on_puzzle_completed)
	layout.crash_event.connect(crash)
	layout.layout_finished.connect(_on_layout_finished)


func update_floor_thumbnail(floor_ind: int) -> void:
	var button_height: int = $UILayer/FloorSelectorPanel.size.y - 30
	
	var changed_floor: FactoryFloor = factory_layouts[floor_ind]
	var select_buttons: Array[Node] = layout_select_row.get_children()
	select_buttons[floor_ind].icon = changed_floor.get_thumbnail(button_height, button_height)

func switch_to_layout_of_button(button: Button) -> void:
	var select_buttons: Array[Node] = layout_select_row.get_children()
	var ind: int = select_buttons.find(button)
	switch_to_layout(ind)
	pass

# Does nothing if given an out-of-bounds layout index
func switch_to_layout(index: int) -> void:
	if( index >= factory_layouts.size() ):
		return
	factory_layouts[active_layout_ind].unhighlight_all()
	active_layout_ind = index
	for layout: FactoryFloor in factory_layouts:
		layout.visible = false
		layout.set_process_unhandled_input(false)
		
	factory_layouts[index].visible = true
	factory_layouts[index].set_process_unhandled_input(true)
	
	
	# Update the inventory for the current layout
	var available_inventory: Array[InventoryItem] = []
	for i: int in range(active_layout_ind):
		var layout: FactoryFloor = factory_layouts[i]
		var this_inventory: Array[InventoryItem] = layout.get_produced_inventory()
		
		# First, remove any products that the layout is using
		var items_to_remove: Array[InventoryItem] = []
		for item: InventoryItem in this_inventory:
			if item.quantity < 0:
				# Find the item in the inventory, and remove the appropriate
				# quantity
				for old_item: InventoryItem in available_inventory:
					if old_item.assembly.matches(item.assembly):
						old_item.quantity += item.quantity
						if old_item.quantity <= 0:
							items_to_remove.append(old_item)
		
		# Get rid of any items with quantities at or below 0
		for item: InventoryItem in items_to_remove:
			available_inventory.erase(item)
		
		# Now add in the things with positive quantities
		
		for item: InventoryItem in this_inventory:
			if item.quantity > 0:
				var added: bool = false
				for old_item: InventoryItem in available_inventory:
					if old_item.assembly.matches(item.assembly):
						old_item.quantity += item.quantity
						added = true
				if( not added ):
					available_inventory.append(item)
		
	depot_control.set_inventory(available_inventory)
	
	update_factory_click_mode()
	hide_all_controls()
	pass
	
func update_factory_click_mode() -> void:
	factory_layouts[active_layout_ind].set_click_mode(click_mode)
	factory_layouts[active_layout_ind].set_widget_type(widget_type)
	factory_layouts[active_layout_ind].set_goal_index(goal_index)
	factory_layouts[active_layout_ind].set_conveyor_direction(conveyor_direction)

#endregion

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
		factory_layouts[active_layout_ind].crash()
		pass
	
	
func hide_all_controls():
	dispenser_control.visible = false
	crane_control.visible = false
	depot_control.visible = false

func show_control(UIElement: Control):
	UIElement.visible = true
	
#region during run behaviors

func initialize_run_money() -> void:
		projected_money = GameState.money
		during_run_costs = 0
		during_run_income = 0
		
		
func crash() -> void:
	crashed = true

#endregion
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	var layout_dicts: Array[Dictionary] = []
	for layout: FactoryFloor in factory_layouts:
		layout_dicts.append(layout.get_save_dict())
	save_dict["layouts"] = layout_dicts
	return save_dict
	
func load_from_save_dict(save_dict: Dictionary):
	
	# Step backwards through layouts and delete all existing layouts.
	for i: int in range(factory_layouts.size()-1, -1, -1):
		remove_layout_at(i)
	for layout_dict: Dictionary in save_dict["layouts"]:
		add_layout(FactoryFloor.create_from_save(layout_dict))
	
	if(factory_layouts.size() > 0):
		switch_to_layout(0)

#endregion


#region button callbacks


func _on_conveyor_select_pressed(direction: float):
	
	conveyor_direction = direction
	click_mode = Consts.PLACE_CONVEYOR
	update_factory_click_mode()


func _on_place_object_pressed():
	click_mode = Consts.PLACE_THING
	widget_type = 1
	update_factory_click_mode()
	
	
func _on_place_widget2_pressed():
	click_mode = Consts.PLACE_THING
	widget_type = 2
	update_factory_click_mode()

func _on_place_dispenser_pressed(type: int):
	click_mode = Consts.PLACE_DISPENSER
	widget_type = type
	update_factory_click_mode()
	pass # Replace with function body.

func _on_place_star_pressed():
	click_mode = Consts.PLACE_STAR_MAKER
	update_factory_click_mode()
	
func _on_place_combiner_pressed():
	click_mode = Consts.PLACE_COMBINER
	update_factory_click_mode()

func _on_place_wall_pressed():
	click_mode = Consts.PLACE_WALL
	update_factory_click_mode()
	
	
func _on_place_track_pressed():
	click_mode = Consts.PLACE_TRACK
	update_factory_click_mode()


func _on_place_crane_pressed():
	click_mode = Consts.PLACE_CRANE
	update_factory_click_mode()
	
func _on_place_goal_pressed(index: int) -> void:
	click_mode = Consts.PLACE_GOAL
	goal_index = index
	update_factory_click_mode()

func _on_place_depot_pressed() -> void:
	click_mode = Consts.PLACE_DEPOT
	update_factory_click_mode()
	
func _on_delete_pressed():
	click_mode = Consts.DELETE
	update_factory_click_mode()
	
	
	
func _on_add_factory_layout_pressed() -> void:
	new_layout()
	
	

func _on_run_speed_pressed(speed: int) -> void:
	if(not running):
		initialize_run_money()
		
	running = true
	hide_all_controls()
	if not crashed:
		Engine.set_time_scale(speed)
		Engine.physics_ticks_per_second = speed*60
		Engine.max_physics_steps_per_frame = speed*8
		factory_layouts[active_layout_ind].run()


func _on_run_all_pressed() -> void:
	if(not whole_factory_running):
		for factory in factory_layouts:
			factory.reset_to_start_of_run()
	
	whole_factory_running = true
	switch_to_layout(0)
	_on_run_speed_pressed(1)



func _on_pause_pressed() -> void:
	factory_layouts[active_layout_ind].pause()


func _on_reset_pressed() -> void:
	factory_layouts[active_layout_ind].reset_to_start_of_run()


func _on_clear_pressed() -> void:
	factory_layouts[active_layout_ind].clear_floor()


func _on_delete_layout_pressed() -> void:
	remove_layout_at(active_layout_ind)
	pass # Replace with function body.

func _on_new_puzzle_pressed() -> void:
	GameState.generate_scenario()
	for layout: FactoryFloor in factory_layouts:
		layout.remove_goals()
	pass

	
#endregion




func _on_floor_modified(layout: FactoryFloor) -> void:
	var floor_ind: int = factory_layouts.find(layout)
	update_floor_thumbnail(floor_ind)
	

func _on_element_selected(element):
	if element is Dispenser:
		dispenser_control.connect_to(element)
		hide_all_controls()
		show_control(dispenser_control)
	
	elif element is Crane:
		crane_control.connect_to(element)
		hide_all_controls()
		show_control(crane_control)
		
	elif element is Depot:
		depot_control.connect_to(element)
		hide_all_controls()
		show_control(depot_control)
		
		
		
	
	
func _on_simulation_cycle_end() -> void:
	GameState.get_scenario().on_new_cycle(self)
	
	
func _on_simulation_reset() -> void:
	money_display.text = "$" + str(GameState.money)
	crashed = false
	running = false
	whole_factory_running = false
	
	


func _on_tutorial_button_pressed():
	$TutorialPanel.visible = true
	
func _on_tutorial_closed():
	$TutorialPanel.visible = false
	
	
# TODO: do I want to handle this with a scenario effect rather
# than hard-coding it?
func _on_assembly_sent(sent: Assembly) -> void:
	change_projected_money(sent.get_value())
	
	
func _on_layout_finished() -> void:
	if(whole_factory_running):
		var next_ind: int = active_layout_ind + 1
		switch_to_layout(next_ind)
		factory_layouts[active_layout_ind].run()
	pass
	

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
	factory_layouts[active_layout_ind].reset_to_start_of_run()
	pass


func _on_win_pressed():
	initialize_run_money()
	_on_puzzle_completed()
