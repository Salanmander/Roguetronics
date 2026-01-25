extends TileMapLayer
class_name FactoryFloor
# Might be worth refactoring this at some point so that the tilemap
# isn't the thing holding all the behavior.

const FLOOR_LAYER = 0

const CONVEYOR_TILE = 4
const CONVEYOR_UP_VARIANT = 0
const CONVEYOR_DOWN_VARIANT = 1
const CONVEYOR_LEFT_VARIANT = 2
const CONVEYOR_RIGHT_VARIANT = 3

const FLOOR_TILE = 0

const NONE = 0
const PLACE_CONVEYOR = 1
const PLACE_THING = 2
const PLACE_COMBINER = 3
const PLACE_DISPENSER = 4
const PLACE_WALL = 5
const PLACE_TRACK = 6
const PLACE_CRANE = 7
const DELETE = 8

signal element_selected(selected)
signal simulation_started()
signal won()

var selected: int = FLOOR_TILE
var selected_variant: int = CONVEYOR_UP_VARIANT

var click_mode: int = NONE
var widget_type: int = 0


var assemblies: Array[Assembly]


var machines: Array[Machine]
var walls: Array[Wall]
var conveyor_direction: float


var dragging_track: bool = false
var current_track: Track
var track_start_square: Vector2i
var tracks: Array[Track]

var starting_assemblies: Array[Assembly]

var goal: Goal

var run: bool = false
var cycle_time: float = 0.7 # Number of seconds for one cycle
var cycle: float = -1 # Current cycle count
var last_cycle: float = 0 # Previous frame cycle count
var crashed: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(50):
		for y in range(40):
			set_cell(Vector2i(x, y), FLOOR_TILE, Vector2i(0,0))
	
	assemblies = []
	machines = []
	walls = []
	tracks = []
	current_track = null

	make_random_goal()
	
	
	
	
	pass # Replace with function body.

#region process updates

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _physics_process(delta: float):
	if run:
		
		# Initial frame. Do first dispense and save initial state
		if cycle == -1:
			for assembly: Assembly in assemblies:
				starting_assemblies.append(assembly.clone())
			
			for machine: Machine in machines:
				if machine is Dispenser:
					machine.do_dispense()
				
			cycle = 0
			return
		
		cycle += delta / cycle_time
		
		
		# Need to combine before checking mobility
		for machine: Machine in machines:
			if machine is Combiner:
				machine.run_to(cycle)
		
		var cycle_fraction = fmod(cycle, 1)
		if cycle - last_cycle >= cycle_fraction:
			goal.check_against(assemblies)
				
		for machine: Machine in machines:
			if not (machine is Combiner):
				machine.run_to(cycle)
			
		for assembly: Assembly in assemblies:
			assembly.run_to(cycle)
			
		
		for assembly: Assembly in assemblies:
			assembly.clear_moves()
			
		
		# This runs if it's the *last* update before the end
		# of the cycle
		if cycle - last_cycle >= (1-cycle_fraction):
			for assembly: Assembly in assemblies:
				assembly.snap_to_grid()
			for machine: Machine in machines:
				if machine is Crane:
					machine.snap_to_grid()
				
			
		last_cycle = cycle
		
	pass

#endregion

#region input
	
func _unhandled_input(event: InputEvent):
	# Only take input on the factory floor if it's not in the middle of
	# the simulation.
	if not is_equal_approx(cycle, -1):
		return
	
	if event is InputEventMouseButton and event.is_pressed():
		event = make_input_local(event)
		var grid_loc: Vector2i = local_to_map(event.position)
		var thing_position: Vector2i = map_to_local(grid_loc)
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Check to see if there's a clickable thing there
			for machine: Machine in machines:
				if not (machine is Dispenser or machine is Crane):
					continue
				
				if (event.position - machine.position).length() < 64:
					unhighlight_all()
					highlight(machine)
					element_selected.emit(machine)
					
				
				
			
		elif(click_mode == PLACE_CONVEYOR):
			# TODO: have framework for getting layer of thing to add
			remove_machines(thing_position, 0)
			make_belt(grid_loc, conveyor_direction)
			
		elif(click_mode == PLACE_THING):
			make_widget(grid_loc, widget_type)
			
		
		elif(click_mode == DELETE):
			# Delete machines
			var removed_machines: Array[Machine] = []
			for machine: Machine in machines:
				if(machine.position.is_equal_approx(thing_position) or 
				   machine.position.distance_squared_to(event.position) < (Consts.GRID_SIZE/2) ** 2):
					remove_child(machine)
					machine.queue_free()
					removed_machines.append(machine)
			for machine: Machine in removed_machines:
				machines.erase(machine)
				
			# Delete walls
			var removed_walls: Array[Wall] = []
			for wall: Wall in walls:
				if(wall.position.is_equal_approx(thing_position)):
					remove_child(wall)
					wall.queue_free()
					removed_walls.append(wall)
			for wall: Wall in removed_walls:
				walls.erase(wall)
			
				
		elif(click_mode == PLACE_COMBINER):
			var TOP = Vector2(0, -1)
			var RIGHT = Vector2(1, 0)
			var BOTTOM = Vector2(0, 1)
			var LEFT = Vector2(-1, 0)
			
			var directions: Array[Vector2] = [TOP, RIGHT, BOTTOM, LEFT]
			var min_dist: float = Consts.GRID_SIZE
			var dir_of_min_dist: Vector2i
			
			for dir in directions:
				var edge_spot: Vector2 = dir*Consts.GRID_SIZE/2.0
				var click_spot: Vector2 = event.position - thing_position*1.0
				click_spot = click_spot.project(dir)
				
				var dist: float = click_spot.distance_to(edge_spot)
				if dist < min_dist:
					min_dist = dist
					dir_of_min_dist = dir
				
			
			if min_dist < Consts.GRID_SIZE/4: 
				make_combiner(grid_loc, dir_of_min_dist)
				
			pass
		elif(click_mode == PLACE_DISPENSER):
			remove_dispenser_type(widget_type)
			make_dispenser(grid_loc, widget_type)
			
			pass
		elif(click_mode == PLACE_WALL):
			make_wall(grid_loc)
			
			pass
		elif(click_mode == PLACE_CRANE):
			var blocked: bool = false
			for track: Track in tracks:
				if track.has_crane_at(grid_loc):
					blocked = true
			
			if not blocked:
				for track: Track in tracks:
					if track.exists_at(grid_loc):
						var new_crane: Crane = make_crane(grid_loc, track)
						
						break
			
			
			pass
		elif click_mode == PLACE_TRACK:
			current_track = null
			
			dragging_track = true
			
			for track: Track in tracks:
				if track.can_grab_at(grid_loc):
					current_track = track

			
			if current_track == null:
				current_track = make_track(grid_loc)
				
			pass
		pass
	elif event is InputEventMouseButton and event.is_released():
		if dragging_track:
			current_track = null
			dragging_track = false
		pass
	elif dragging_track and event is InputEventMouseMotion:
		event = make_input_local(event)
		var grid_loc: Vector2i = local_to_map(event.position)
		var dist_sq = map_to_local(grid_loc).distance_squared_to(event.position)
		if dist_sq <= pow(Consts.GRID_SIZE/2, 2):
			current_track.drag_to(grid_loc)
		
		#if grid_loc != track_start_square:
			#var new_line:Line2D = Line2D.new()
			#var points:Array[Vector2] = [map_to_local(track_start_square),
										 #map_to_local(grid_loc)]
			#new_line.points = PackedVector2Array(points)
			#add_child(new_line)
			#
			#track_start_square = grid_loc
			#
		#pass
	pass
	

func unhighlight_all():
	for machine: Machine in machines:
		machine.unhighlight()
		
func highlight(machine: Machine):
	machine.highlight()
	
#endregion
	
#region object creating functions

func make_widget(grid_position: Vector2i, init_widget_type: int) -> Assembly:
	var widget_position: Vector2 = map_to_local(grid_position)
	var new_assembly:Assembly = Assembly.create(widget_position)
	new_assembly.add_widget(Vector2(0, 0), init_widget_type) 
	add_child(new_assembly)
	assemblies.append(new_assembly)
	new_assembly.deleted.connect(_on_assembly_delete)
	new_assembly.crashed.connect(crash)
	
	return new_assembly
	
func make_wall(grid_position: Vector2i) -> void:
	var wall_position: Vector2 = map_to_local(grid_position)
	var new_wall:Wall = Wall.create(wall_position)
	add_wall(new_wall)
	
func add_wall(new_wall: Wall) -> void:
	add_child(new_wall)
	walls.append(new_wall)
	
func make_belt(grid_position: Vector2i, direction: float):
	var belt_position: Vector2 = map_to_local(grid_position)
	var new_machine:Belt = Belt.create(belt_position, direction)
	machines.append(new_machine)
	add_child(new_machine)
	
func make_dispenser(grid_position: Vector2i, dispense_type: int) -> void:
	var dispenser_position: Vector2 = map_to_local(grid_position)
	var new_dispenser:Dispenser = Dispenser.create(dispenser_position, dispense_type)
	add_dispenser(new_dispenser)
	
func add_dispenser(new_dispenser: Dispenser) -> void:
	add_child(new_dispenser)
	machines.append(new_dispenser)
	new_dispenser.dispense.connect(_on_dispense)
	
	# TODO: Better solution for getting rid of interface for
	# dispensers that no longer exist 
	unhighlight_all()
	highlight(new_dispenser)
	element_selected.emit(new_dispenser)
	
	
func make_combiner(grid_position: Vector2i, offset_dir:Vector2i):
	
	var combiner_position: Vector2 = map_to_local(grid_position)
	var direction = 0
	if(offset_dir.y == 0):
		direction = PI/2
	var new_combiner = Combiner.create(Vector2(combiner_position) + offset_dir*Consts.GRID_SIZE/2, direction)
	add_child(new_combiner)
	machines.append(new_combiner)
	
func make_track(grid_position: Vector2i) -> Track:
	var new_track: Track = Track.create(grid_position)
	tracks.append(new_track)
	add_child(new_track)
	return new_track

func make_crane(grid_position: Vector2i, parent: Track) -> Crane:
	
	var crane_position: Vector2 = map_to_local(grid_position)
	var new_crane: Crane = Crane.create(crane_position)
	machines.append(new_crane)
	new_crane.crashed.connect(crash)
	parent.add_crane(new_crane)
	
	return new_crane
	
func add_goal(new_goal: Goal):
	if(goal):
		goal.queue_free()
	goal = new_goal
	add_child(goal)
	goal.completed.connect(_on_goal_completed.bind(goal))
	
func make_random_goal():
	
	var new_goal: Goal = PuzzleManager.get_random_goal()
	new_goal.set_goal_position(map_to_local(Vector2i(10, 2)))
	add_goal( new_goal)
	
	
	
#endregion
	
	
func remove_machines(machine_position: Vector2, machine_layer: int):
	var i:int = machines.size() - 1
	while i >= 0:
		if(machines[i].z_index == machine_layer):
			
			var dist_sq:float = machines[i].position.distance_squared_to(machine_position)
			
			# If the machine is within 1/4 grid-width
			if  dist_sq < Consts.GRID_SIZE*Consts.GRID_SIZE/16:
				remove_child(machines[i])
				machines[i].queue_free()
				machines.remove_at(i)
				
		i -= 1
	pass

	
#region Resetting

func win():
	won.emit()

# TODO: improve the crash, give visual indicator of the thing that caused
# the crash
func crash():
	run = false
	crashed = true
	modulate = Color(1, 0.6, 0.6, 1)

func reset_to_start_of_run():
	delete_assemblies()
	cycle = -1
	crashed = false
	modulate = Color(1, 1, 1, 1)
	
	assemblies = starting_assemblies
	starting_assemblies = []
	
	for assembly: Assembly in assemblies:
		add_child(assembly)
		assembly.deleted.connect(_on_assembly_delete)
		assembly.crashed.connect(crash)
		
	for machine:Machine in machines:
		machine.reset()
		
	goal.reset()
	
	_on_pause_pressed()


func delete_assemblies():
	
	# The assembly delete method removes it from the assemblies array
	# (indirectly), so we need to duplicate the array first.
	for assembly: Assembly in assemblies.duplicate():
		assembly.delete()
		

func delete_machines():
	for machine: Machine in machines:
		machine.queue_free()
		
	machines = []

	
func delete_walls():
	var child_list: Array[Node] = get_children()
	
	for child: Node in child_list:
		if child is Wall:
			child.queue_free()
			
func delete_tracks():
	for track: Track in tracks:
		track.queue_free()
	
	tracks = []
	
		
func remove_dispenser_type(widget_type: int):
	
	for machine: Machine in machines.duplicate():
		if machine is Dispenser and machine.get_type() == widget_type:
			machines.erase(machine)
			machine.queue_free()
	
	pass

#endregion

# Teardown to free nodes held in arrays but not in the scene tree
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for assembly:Assembly in starting_assemblies:
			assembly.queue_free()


#region saveAndLoad

# Saves data necessary to re-build the factory floor state.
# Want to preserve everything that stays when you stop the simulation:
#   machines, goal, walls, tracks

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["goal"] = goal.get_save_dict()
	
	var wall_dicts: Array = []
	for wall: Wall in walls:
		wall_dicts.append(wall.get_save_dict())
	save_dict["walls"] = wall_dicts
	
	var disp_dicts: Array = []
	for machine: Machine in machines:
		if machine is Dispenser:
			disp_dicts.append(machine.get_save_dict())
	save_dict["disps"] = disp_dicts
		
	return save_dict
	
func load_from_save_dict(save_dict: Dictionary):
	
	var new_goal: Goal = Goal.create_from_save(save_dict["goal"])
	add_goal(new_goal)
	
	for wall_dict: Dictionary in save_dict["walls"]:
		var new_wall: Wall = Wall.create_from_save(wall_dict)
		add_wall(new_wall)
		
	for disp_dict: Dictionary in save_dict["disps"]:
		var new_dispenser: Dispenser = Dispenser.create_from_save(disp_dict)
		add_dispenser(new_dispenser)
	
	
	pass

#endregion

#region button callbacks and signal connectors


func _on_assembly_delete(deleted: Assembly):
	assemblies.erase(deleted)

# TODO: do I want this to also have a way to note the goal object?
# should the goal object keep track of how many things it needs?
# Should it still send the number completed?
func _on_goal_completed(goal: Goal):
	won.emit()
	
func _on_dispense(loc: Vector2, init_widget_type: int):
	make_widget(local_to_map(loc), init_widget_type)

	
func _on_conveyor_select_pressed(direction: float):
	conveyor_direction = direction
	click_mode = PLACE_CONVEYOR


func _on_place_object_pressed():
	click_mode = PLACE_THING
	widget_type = 1
	
	
func _on_place_widget2_pressed():
	click_mode = PLACE_THING
	widget_type = 2

func _on_place_dispenser_pressed(type: int):
	click_mode = PLACE_DISPENSER
	widget_type = type
	pass # Replace with function body.

	
func _on_place_combiner_pressed():
	click_mode = PLACE_COMBINER

func _on_place_wall_pressed():
	click_mode = PLACE_WALL
	
	
func _on_place_track_pressed():
	click_mode = PLACE_TRACK


func _on_place_crane_pressed():
	click_mode = PLACE_CRANE
	
	
func _on_delete_pressed():
	click_mode = DELETE




func _on_run_pressed() -> void:
	if not crashed:
		simulation_started.emit()
		unhighlight_all()
		run = true



func _on_pause_pressed() -> void:
	run = false

	

func _on_reset_pressed():
	
	reset_to_start_of_run()
		


func _on_clear_pressed():
	delete_assemblies()
	delete_machines()
	delete_walls()
	delete_tracks()
	reset_to_start_of_run()
	
func _on_new_puzzle_pressed():
	make_random_goal()
	
	
func _on_save_pressed() -> void:
	GameState.save_to_disk()


#endregion



#region Debug helpers

func setup_debug_objects():
	
	goal = Goal.create(map_to_local(Vector2i(10,2)))
	goal.add_widget(Vector2(0,0), 2)
	goal.add_widget(Vector2(Consts.GRID_SIZE,0), 1)
	goal.add_widget(Vector2(2*Consts.GRID_SIZE,0), 2)
	goal.add_widget(Vector2(3*Consts.GRID_SIZE,0), 1)
	
	goal.add_link(Vector2(0,0), Vector2(Consts.GRID_SIZE,0))
	goal.add_link(Vector2(Consts.GRID_SIZE,0), Vector2(2*Consts.GRID_SIZE,0))
	goal.add_link(Vector2(2*Consts.GRID_SIZE,0), Vector2(3*Consts.GRID_SIZE,0))
	add_goal(goal)
	

func _on_test_function_pressed():
	for machine in machines:
		if machine is Crane:
			if machine.is_open():
				machine.close()
			else:
				machine.open()

	

#endregion
