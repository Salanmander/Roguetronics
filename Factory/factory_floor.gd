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
const WALL_TILE = 5


signal floor_changed()
signal element_selected(selected: Machine)
signal simulation_reset()
signal simulation_cycle_end()
signal simulation_started()
signal first_cycle_started()
signal assembly_sent(sent: Assembly)
signal crash_event()
signal won()


var view_size: Vector2i

var selected: int = FLOOR_TILE
var selected_variant: int = CONVEYOR_UP_VARIANT

var click_mode: int = Consts.NONE
var widget_type: int = 0
var goal_index: int = 0


var assemblies: Array[Assembly]


var machines: Array[Machine]
var walls: Array[Wall]
var conveyor_direction: float


var dragging_track: bool = false
var current_track: Track
var track_start_square: Vector2i

var starting_assemblies: Array[Assembly]


var goals: Array[Goal]

var running: bool = false
var cycle_time: float = 0.7 # Number of seconds for one cycle
var cycle: float = -1 # Current cycle count
var last_cycle: float = 0 # Previous frame cycle count
var crashed: bool = false


#region constructors

static func create() -> FactoryFloor:
	var new_floor: FactoryFloor = FactoryFloor.new()
	return new_floor
	
static func create_from_save(save_dict: Dictionary) -> FactoryFloor:
	var new_floor: FactoryFloor = FactoryFloor.new()
	new_floor.load_from_save_dict(save_dict)
	return new_floor
	
# Setup things that may change before adding to the scene tree
func _init() -> void:
	tile_set = load("res://Factory/factory_floor_tileset.tres")
	
	set_tile_textures()
	create_outer_walls()
			
	walls = []
	
	assemblies = []
	machines = []
	current_track = null
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# view_size should always get set, but the parent needs to be
	# ready before that happens.
	
	pass # Replace with function body.
	
func set_tile_textures() -> void:
	
	var floor_space: Array[Array] = GameState.factory_space
	for x in range(-15,30):
		for y in range(-10, 20):
			if x < 0 or y < 0:
				set_cell(Vector2i(x, y), WALL_TILE, Vector2i(0,0))
			elif(x >= floor_space.size() or y >= floor_space[0].size()):
				set_cell(Vector2i(x, y), WALL_TILE, Vector2i(0,0))
			else:
				if(floor_space[x][y]):
					set_cell(Vector2i(x, y), FLOOR_TILE, Vector2i(0,0))
				else:
					set_cell(Vector2i(x, y), WALL_TILE, Vector2i(0,0))
					

func create_outer_walls() -> void:
	
	var floor_space: Array[Array] = GameState.factory_space
	var wall_array: Array[Array] = []
	
	wall_array.resize(floor_space.size() + 2)
	for x in range(wall_array.size()):
		wall_array[x].resize(floor_space[0].size() + 2)
		for y in range(wall_array[x].size()):
			wall_array[x][y] = true
	
	# Make the Walls array be the inverse of the floor space array
	for x in range(floor_space.size()):
		for y in range(floor_space[0].size()):
			if(floor_space[x][y]):
				wall_array[x+1][y+1] = false
				
	# Remove any walls that aren't touching floor space
	for x in range(wall_array.size()):
		for y in range(wall_array[0].size()):
			var near_floor: bool = false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					var floor_x = x + dx - 1
					var floor_y = y + dy - 1
					if(floor_x < 0 or floor_x >= floor_space.size()):
						continue
					if(floor_y < 0 or floor_y >= floor_space[0].size()):
						continue
					if(floor_space[floor_x][floor_y]):
						near_floor = true
			
			if(not near_floor):
				wall_array[x][y] = false
		
	# Actually create the walls
	
	for x in range(wall_array.size()):
		for y in range(wall_array[0].size()):
			if(wall_array[x][y]):
				# (0,0) in the wall array is -1,-1 on the floor grid,
				# since it's expanded by one in every direction from the
				# factory floor
				make_wall(Vector2i(x-1, y-1))
					
#endregion

#region controls from Factory


func set_click_mode(mode: int) -> void:
	click_mode = mode
	
func set_widget_type(type: int) -> void:
	widget_type = type

func set_conveyor_direction(dir: float) -> void:
	conveyor_direction = dir

func set_goal_index(index: int) -> void:
	goal_index = index

func set_speed(speedup: int) -> void:
	Engine.set_time_scale(speedup)
	Engine.physics_ticks_per_second = speedup*60
	Engine.max_physics_steps_per_frame = speedup*8
	running = true
	simulation_started.emit()
	unhighlight_all()


func clear_floor() -> void:
	delete_assemblies()
	delete_machines()
	floor_changed.emit()
	# Should only re-add this if walls are being voluntarily added.
	# Currently walls are what prevents widgets from going outside the
	# factory.
	#delete_walls()
	reset_to_start_of_run()

#endregion

#region process updates

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _physics_process(delta: float):
	if running:
		
		# Initial frame. Do first dispense and save initial state
		if cycle == -1:
			
			for assembly: Assembly in assemblies:
				starting_assemblies.append(assembly.clone())
			
			for machine: Machine in machines:
				if machine is Dispenser:
					machine.do_dispense()
				
			cycle = 0
			first_cycle_started.emit()
			return
		
		cycle += delta / cycle_time
		

		# Need to combine before checking mobility
		for machine: Machine in machines:
			if machine is Combiner:
				machine.run_to(cycle)
		
		# This runs if it's the first update of the cycle
		var cycle_fraction = fmod(cycle, 1)
		if cycle - last_cycle >= cycle_fraction:
			for goal: Goal in goals:
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
			simulation_cycle_end.emit()
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
			var highlighted: Machine = null
			for machine: Machine in machines:
				if machine is Dispenser:
					if (event.position - machine.position).length() < 64:
						highlighted = highlight(machine, grid_loc)
						
				if machine is Track:
					if machine.exists_at(grid_loc):
						highlighted = highlight(machine, grid_loc)
					pass
					
			
			if highlighted != null:
				unhighlight_all()
				
				# This is a little hacky, because it involves us calling
				# highlight on the same object twice. But calling highlight
				# is how we know whether anything got highlighted, and
				# we need to only do the unhighlight of something got
				# highlighted.
				highlight(highlighted, grid_loc)
				element_selected.emit(highlighted)
					
				
				
			
		elif(click_mode == Consts.PLACE_GOAL):
			
			var scenario_goals: Array[Goal] = GameState.get_scenario().get_goals()
			var goal_to_add: Goal = scenario_goals[goal_index]
			goal_to_add.set_goal_position(thing_position)
			
			add_goal(goal_to_add)
			floor_changed.emit()
			
		elif(click_mode == Consts.PLACE_CONVEYOR):
			remove_machines(thing_position, Belt.LAYER)
			make_belt(grid_loc, conveyor_direction)
			floor_changed.emit()
			
		elif(click_mode == Consts.PLACE_THING):
			make_widget(grid_loc, widget_type)
			floor_changed.emit()
			
		
		elif(click_mode == Consts.DELETE):
			# Delete machines
			var something_changed: bool = false
			var removed_machines: Array[Machine] = []
			for machine: Machine in machines:
				if(machine is Track and machine.has_crane_at(grid_loc)):
					machine.delete_crane_at(grid_loc)
					something_changed = true
					
				if(machine.position.is_equal_approx(thing_position) or 
				   machine.position.distance_squared_to(event.position) < (Consts.GRID_SIZE/2) ** 2):
					remove_child(machine)
					machine.queue_free()
					removed_machines.append(machine)
					something_changed = true
			for machine: Machine in removed_machines:
				machines.erase(machine)
				
			# Delete walls (Should only re-add this if walls
			# are being voluntarily added.)
			#var removed_walls: Array[Wall] = []
			#for wall: Wall in walls:
				#if(wall.position.is_equal_approx(thing_position)):
					#remove_child(wall)
					#wall.queue_free()
					#removed_walls.append(wall)
					#something_changed = true
			#for wall: Wall in removed_walls:
				#walls.erase(wall)
			
			if(something_changed):
				floor_changed.emit()
			
			
				
		elif(click_mode == Consts.PLACE_COMBINER):
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
				floor_changed.emit()
				
			pass
		elif(click_mode == Consts.PLACE_DISPENSER):
			remove_dispenser_type(widget_type)
			make_dispenser(grid_loc, widget_type)
			floor_changed.emit()
			
			pass
		elif(click_mode == Consts.PLACE_STAR_MAKER):
			remove_star_makers()
			remove_machines(thing_position, StarMaker.LAYER)
			make_star_maker(grid_loc)
			floor_changed.emit()
			
			pass
		elif(click_mode == Consts.PLACE_WALL):
			make_wall(grid_loc)
			floor_changed.emit()
			
			pass
		elif(click_mode == Consts.PLACE_CRANE):
			var blocked: bool = false
			for track: Machine in machines:
				if track is Track and track.has_crane_at(grid_loc):
					blocked = true
			
			if not blocked:
				for track: Machine in machines:
					if track is Track and track.exists_at(grid_loc):
						make_crane(grid_loc, track)
						floor_changed.emit()
						
						break
			
			
			pass
		elif click_mode == Consts.PLACE_TRACK:
			current_track = null
			
			dragging_track = true
			
			for track: Machine in machines:
				if track is Track and track.can_grab_at(grid_loc):
					current_track = track

			
			if current_track == null:
				current_track = make_track(grid_loc)
				floor_changed.emit()
				
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
			floor_changed.emit()
		
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
		
# The grid location is used by some machines but not others to figure out what to
# highlight. If it's not given, assumed to be useless.
func highlight(machine: Machine, grid_loc: Vector2i = Vector2i(0,0)) -> Machine:
	var highlighted: Machine = machine.highlight(grid_loc)
	return highlighted
	
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
	walls.append(new_wall)
	add_child(new_wall)
	
func make_belt(grid_position: Vector2i, direction: float) -> void:
	var belt_position: Vector2 = map_to_local(grid_position)
	var new_belt:Belt = Belt.create(belt_position, direction)
	add_belt(new_belt)
	
func add_belt(new_belt: Belt) -> void:
	machines.append(new_belt)
	add_child(new_belt)
	
func make_star_maker(grid_position: Vector2i) -> void:
	var star_maker_position: Vector2 = map_to_local(grid_position)
	var new_star_maker: StarMaker = StarMaker.create(star_maker_position)
	add_star_maker(new_star_maker)
	
func add_star_maker(new_star_maker: StarMaker) -> void:
	add_child(new_star_maker)
	machines.append(new_star_maker)
	
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
	
	
func make_combiner(grid_position: Vector2i, offset_dir:Vector2i) -> void:
	
	var combiner_position: Vector2 = map_to_local(grid_position)
	var direction = 0
	if(offset_dir.y == 0):
		direction = PI/2
	var new_combiner = Combiner.create(Vector2(combiner_position) + offset_dir*Consts.GRID_SIZE/2, direction)
	add_combiner(new_combiner)
	
func add_combiner(new_combiner: Combiner) -> void:
	machines.append(new_combiner)
	add_child(new_combiner)
	
	
func make_track(grid_position: Vector2i) -> Track:
	var new_track: Track = Track.create(grid_position)
	add_track(new_track)
	return new_track
	
func add_track(new_track: Track) -> void:
	new_track.crashed.connect(crash)
	machines.append(new_track)
	add_child(new_track)
	
func make_crane(grid_position: Vector2i, parent: Track) -> Crane:
	
	var crane_position: Vector2 = map_to_local(grid_position)
	var new_crane: Crane = Crane.create(crane_position)
	parent.add_crane(new_crane)
	return new_crane
	

func add_machine(new_machine: Machine) -> void:
	if new_machine is Belt:
		add_belt(new_machine)
	elif new_machine is Dispenser:
		add_dispenser(new_machine)
	elif new_machine is Combiner:
		add_combiner(new_machine)
	elif new_machine is Track:
		add_track(new_machine)
	elif new_machine is StarMaker:
		add_star_maker(new_machine)
	else:
		assert(false, "Tried to add machine that shouldn't be added")
	
	
func add_goal(goal_to_add: Goal) -> void:
	
	var existing_parent: Node = goal_to_add.get_parent()
	if(existing_parent):
		existing_parent.remove_goal(goal_to_add)
	goals.append(goal_to_add)
	add_child(goal_to_add)
	goal_to_add.completed.connect(_on_goal_completed.bind(goal_to_add))
	goal_to_add.assembly_sent.connect(_on_assembly_sent)
	pass
	
func remove_goal(old_goal: Goal) -> void:
	var conns: Array[Dictionary] = old_goal.get_signal_connection_list("completed")
	for conn: Dictionary in conns:
		old_goal.disconnect("completed", conn.callable)
	conns = old_goal.get_signal_connection_list("assembly_sent")
	for conn: Dictionary in conns:
		old_goal.disconnect("assembly_sent", conn.callable)
	
	if not old_goal in goals:
		return
	goals.erase(old_goal)
	remove_child(old_goal)
	
	
func make_random_goal() -> void:
	
	var new_goal: Goal = PuzzleManager.get_random_goal()
	new_goal.set_goal_position(map_to_local(Vector2i(10, 2)))
	add_goal( new_goal)
	
	
	
#endregion


func get_thumbnail(width: int, height: int) -> ImageTexture:
	
	const CEL_PX: int = 5
	const FLOOR_C: Color = Color(0.9, 0.8, 0.6)
	const BELT_C: Color = Color(0.3, 0.3, 0.3)
	#const MACHINE_C: Color = Color(0.9, 0.9, 0.9)
	const DISP_Cs: Dictionary = {
		1: Color(0.8, 0.4, 0.1), 
		2: Color(0.1, 0.8, 0.2),
		}
	
	var floor_space: Array[Array] = GameState.factory_space
	var thumb_wid: int = floor_space.size() * CEL_PX
	var thumb_hgt: int = floor_space[0].size() * CEL_PX
	var thumb: Image = Image.create_empty(thumb_wid, thumb_hgt, false, Image.FORMAT_RGB8)
	
	for x: int in range(floor_space.size()):
		for y: int in range(floor_space[0].size()):
			if(floor_space[x][y]):
				thumb.fill_rect(Rect2i(x*CEL_PX, y*CEL_PX, CEL_PX, CEL_PX), FLOOR_C)
				
	for machine: Machine in machines:
		if machine is Belt:
			var grid_loc: Vector2i = local_to_map(machine.position)
			var x: int = grid_loc.x
			var y: int = grid_loc.y
			thumb.fill_rect(Rect2i(x*CEL_PX, y*CEL_PX, CEL_PX, CEL_PX), BELT_C)
		if machine is Dispenser:
			var grid_loc: Vector2i = local_to_map(machine.position)
			var x: int = grid_loc.x
			var y: int = grid_loc.y
			var color: Color = DISP_Cs[machine.type]
			thumb.fill_rect(Rect2i(x*CEL_PX, y*CEL_PX, CEL_PX, CEL_PX), color)
	
	var scale_factor: float = 1
	if(thumb_wid >= thumb_hgt):
		# Determine space available for actual thumbnail inside frame by
		# the width. One CEL_PX on either side, then scaled down to the frame
		var full_wid: int = thumb_wid + 2*CEL_PX
		scale_factor = width/float(full_wid)
	else:
		var full_hgt: int = thumb_hgt + 2*CEL_PX
		scale_factor = height/float(full_hgt)
	
	var new_wid: int = int(scale_factor * thumb_wid)
	var new_hgt: int = int(scale_factor * thumb_hgt)
	thumb.resize(new_wid, new_hgt, Image.INTERPOLATE_NEAREST)
		
	var dest: Vector2i = Vector2i((width - new_wid)/2, (height - new_hgt)/2)
	var src: Rect2i = Rect2i(0, 0, new_wid, new_hgt)
	var frame: Image = Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	
	frame.blit_rect(thumb, src, dest)
	return ImageTexture.create_from_image(frame)
	
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


func win() -> void:
	pause()
	won.emit()
	

# TODO: improve the crash, give visual indicator of the thing that caused
# the crash
func crash() -> void:
	running = false
	crashed = true
	crash_event.emit()
	modulate = Color(1, 0.6, 0.6, 1)
	
func pause() -> void:
	running = false

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
	
	for goal: Goal in goals:
		goal.reset()
	
	simulation_reset.emit()
	
	pause()


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
			
	
		
func remove_dispenser_type(widget_type: int) -> void:
	
	for machine: Machine in machines.duplicate():
		if machine is Dispenser and machine.get_type() == widget_type:
			machines.erase(machine)
			machine.queue_free()
	

func remove_star_makers() -> void:
	
	for machine: Machine in machines.duplicate():
		if machine is StarMaker:
			machines.erase(machine)
			machine.queue_free()

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
	
	var goal_dicts: Array = []
	for goal: Goal in goals:
		goal_dicts.append(goal.get_save_dict())
	save_dict["goals"] = goal_dicts
	
	var wall_dicts: Array = []
	for wall: Wall in walls:
		wall_dicts.append(wall.get_save_dict())
	save_dict["walls"] = wall_dicts
	
	var machine_dicts: Array = []
	for machine: Machine in machines:
		machine_dicts.append(machine.get_save_dict())
	save_dict["machines"] = machine_dicts
	
		
	return save_dict
	
func load_from_save_dict(save_dict: Dictionary):
	
	for goal_dict: Dictionary in save_dict["goals"]:
		var new_goal: Goal = Goal.create_from_save(goal_dict)
		add_goal(new_goal)
	
	for wall_dict: Dictionary in save_dict["walls"]:
		var new_wall: Wall = Wall.create_from_save(wall_dict)
		add_wall(new_wall)
		
		
	for machine_dict: Dictionary in save_dict["machines"]:
		var new_machine: Machine = Machine.create_from_save(machine_dict)
		add_machine(new_machine)
		
	floor_changed.emit()
	
	
	pass

#endregion



#region button callbacks and signal connectors


func _on_assembly_delete(deleted: Assembly):
	assemblies.erase(deleted)

# TODO: do I want this to also have a way to note the goal object?
# should the goal object keep track of how many things it needs?
# Should it still send the number completed?
func _on_goal_completed(_goal: Goal):
	win()

func _on_assembly_sent(sent: Assembly) -> void:
	assembly_sent.emit(sent)
	
func _on_dispense(loc: Vector2, init_widget_type: int):
	make_widget(local_to_map(loc), init_widget_type)


	
	
func _on_save_pressed() -> void:
	GameState.save_to_disk()


#endregion



#region Debug helpers

func setup_debug_objects():
	
	var goal = Goal.create(map_to_local(Vector2i(10,2)))
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
