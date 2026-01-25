extends Node

func get_random_goal()-> Goal:
	
	# Check to see if combiner exists
	var machines: Array[MachinePrototype] = GameState.get_machines_available()
	
	var widget_types: Array[int] = []
	var can_combine: bool = false
	var has_crane: bool = false
	for machine: MachinePrototype in machines:
		var machine_name: String = machine.get_script().get_global_name()
		if machine_name == "CranePrototype":
			has_crane = true
	
		if machine_name == "CombinerPrototype":
			can_combine = true
		
		if machine_name == "DispenserPrototype":
			widget_types = machine.get_widget_types()
	
	if widget_types.size() == 0:
		widget_types = [1]
			
	if not can_combine:
		return get_nocombine_goal(widget_types)
	
	if not has_crane:
		return get_belt_only_goal(widget_types)
	
	return get_full_random_goal(widget_types)

func get_nocombine_goal(widget_types: Array[int]) -> Goal:
	var goal: Goal = Goal.create(Vector2(0,0))
	goal.add_widget(Vector2(0,0), widget_types.pick_random())
	return goal
	
func get_belt_only_goal(widget_types: Array[int]) -> Goal:
	var goal: Goal = Goal.create(Vector2(0,0))
	
	var primary: int = widget_types.pick_random()
	var secondary: int = widget_types.pick_random()
	
	var unit_size: int = randi_range(2, 4)
	var unit_repeats: int = randi_range(1, 2)
	
	var secondary_loc: int = randi_range(0, unit_size)
	
	var cur_pos: Vector2 = Vector2(0, 0)
	
	
	var directions: Array[Vector2] = \
		[Vector2(Consts.GRID_SIZE,0),\
		 Vector2(0, Consts.GRID_SIZE)]
	
	var dir1 = directions.pick_random()
	var dir2 = directions.pick_random()
		
	
	for i in range(unit_size):
		var widget_type = primary
		if i == secondary_loc:
			widget_type = secondary
			
		goal.add_widget(cur_pos, widget_type)
		
		if i > 0:
			var expand_from = cur_pos - dir1
			goal.add_link(expand_from, cur_pos)
		
		cur_pos += dir1
		
	return goal
		
		
	
	
	
			
func get_full_random_goal(widget_types: Array[int]) -> Goal:
	var goal: Goal = Goal.create(Vector2(0,0))
	
	var num_widgets: int = randi_range(3,5)
	
	var current_locations: Array[Vector2] = [Vector2(0, 0)]
	
	goal.add_widget(Vector2(0,0), widget_types.pick_random())
	
	var directions: Array[Vector2] = \
		[Vector2(Consts.GRID_SIZE,0),\
		 Vector2(0, Consts.GRID_SIZE)]
		
	for i in range(1, num_widgets):
		# pick one of the current locations to expand from
		var expand_from: Vector2 = current_locations.pick_random()
		
		# Expand in a random direction. Retry as long as that direction
		# already has a widget in it
		var expand_to: Vector2 = expand_from + directions.pick_random()
		var num_tries: int = 0
		while expand_to in current_locations:
			expand_to = expand_from + directions.pick_random()
			num_tries += 1
			if num_tries > 8:
				break
		
		# If we've tried a bunch of times, just don't add a widget this time,
		# that's fine.
		if num_tries > 8:
			continue
		
		
		goal.add_widget(expand_to, widget_types.pick_random())
		current_locations.append(expand_to)
		goal.add_link(expand_from, expand_to)
		
	return goal
