extends TileMap
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
const MODIFY_FLOOR = 1
const PLACE_THING = 2
const PLACE_COMBINER = 3
const PLACE_DISPENSER = 4
const PLACE_WALL = 5
const PLACE_TRACK = 6

signal element_selected(selected)
signal simulation_started()

var selected:int = FLOOR_TILE
var selected_variant:int = CONVEYOR_UP_VARIANT

var click_mode:int = NONE
var widget_type:int = 0

var wall_packed:PackedScene = load("res://Factory/Wall/wall.tscn")

var widget_packed:PackedScene = load("res://Factory/Widget/widget.tscn")
var assembly_packed:PackedScene = load("res://Factory/Assembly/assembly.tscn")
var assemblies:Array[Assembly]


var belt_packed:PackedScene = load("res://Factory/Machine/Belt/belt.tscn")
var combiner_packed:PackedScene = load("res://Factory/Machine/Combiner/combiner.tscn")
var dispenser_packed:PackedScene = load("res://Factory/Machine/Dispenser/dispenser.tscn")
var machines:Array[Machine]
var conveyor_direction:float


var track_packed:PackedScene = load("res://Factory/Machine/Crane/track.tscn")
var dragging_track:bool = false
var current_track:Track
var track_start_square:Vector2i
var tracks:Array[Track]

var starting_assemblies:Array[Assembly]

var goal_packed:PackedScene = load("res://Factory/Goal/goal.tscn")
var goal:Goal

var run:bool = false
var cycle_time:float = 0.7 # Number of seconds for one cycle
var cycle:float = -1 # Current cycle count
var last_cycle:float = 0 # Previous frame cycle count


# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(50):
		for y in range(40):
			set_cell(FLOOR_LAYER, Vector2i(x, y), FLOOR_TILE, Vector2i(0,0))
	
	assemblies = []
	machines = []
	tracks = []
	current_track = null

	setup_debug_objects()
	
	add_child(goal)
	
	pass # Replace with function body.

#region process updates

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _physics_process(delta: float):
	if run:
		
		# Initial frame. Do first dispense and save initial state
		if cycle == -1:
			for assembly:Assembly in assemblies:
				starting_assemblies.append(assembly.clone())
			
			for machine:Machine in machines:
				if machine is Dispenser:
					machine.do_dispense()
				
			cycle = 0
			return
		
		cycle += delta / cycle_time
		
		
		# Need to combine before checking mobility
		for machine:Machine in machines:
			if machine is Combiner:
				machine.run_to(cycle)
		
		var cycle_fraction = fmod(cycle, 1)
		if cycle - last_cycle >= cycle_fraction:
			goal.check()
				
		for machine:Machine in machines:
			if not (machine is Combiner):
				machine.run_to(cycle)
			
		for assembly:Assembly in assemblies:
			assembly.run_to(cycle)
			
		
		for assembly:Assembly in assemblies:
			assembly.clear_nudges()
			
		
		# This runs if it's the *last* update before the end
		# of the cycle
		if cycle - last_cycle >= (1-cycle_fraction):
			for assembly:Assembly in assemblies:
				assembly.snap_to_grid(self)
			
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
		var grid_loc:Vector2i = local_to_map(event.position)
		var thing_position:Vector2i = map_to_local(grid_loc)
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Check to see if there's a clickable thing there
			for machine:Machine in machines:
				if not machine is Dispenser:
					continue
				
				if (event.position - machine.position).length() < 64:
					unhighlight_all()
					highlight(machine)
					element_selected.emit(machine)
				
				
			
		elif(click_mode == MODIFY_FLOOR):
			# TODO: have framework for getting layer of thing to add
			remove_machines(thing_position, 0)
			make_belt(grid_loc, conveyor_direction)
			
		elif(click_mode == PLACE_THING):
			make_widget(grid_loc, widget_type)
				
		elif(click_mode == PLACE_COMBINER):
			var TOP = Vector2(0, -1)
			var RIGHT = Vector2(1, 0)
			var BOTTOM = Vector2(0, 1)
			var LEFT = Vector2(-1, 0)
			
			var directions:Array[Vector2] = [TOP, RIGHT, BOTTOM, LEFT]
			var min_dist:float = Consts.GRID_SIZE
			var dir_of_min_dist:Vector2i
			
			for dir in directions:
				var edge_spot:Vector2 = dir*Consts.GRID_SIZE/2.0
				var click_spot:Vector2 = event.position - thing_position*1.0
				click_spot = click_spot.project(dir)
				
				var dist:float = click_spot.distance_to(edge_spot)
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
		elif click_mode == PLACE_TRACK:
			dragging_track = true
			current_track = track_packed.instantiate()
			add_child(current_track)
			
			current_track.click_at(grid_loc)
			
			pass
		pass
	elif event is InputEventMouseButton and event.is_released():
		if dragging_track:
			current_track = null
			dragging_track = false
		pass
	elif dragging_track and event is InputEventMouseMotion:
		event = make_input_local(event)
		var grid_loc:Vector2i = local_to_map(event.position)
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
	for machine:Machine in machines:
		machine.unhighlight()
		
func highlight(machine: Machine):
	machine.highlight()
	
#endregion
	
#region object creating functions

func make_widget(grid_position: Vector2i, init_widget_type: int):
	var widget_position: Vector2 = map_to_local(grid_position)
	var new_assembly:Assembly = assembly_packed.instantiate()
	new_assembly.set_parameters(widget_position)
	new_assembly.add_widget(Vector2(0, 0), init_widget_type) 
	add_child(new_assembly)
	assemblies.append(new_assembly)
	new_assembly.deleted.connect(_on_assembly_delete)
	
func make_wall(grid_position: Vector2i):
	var wall_position: Vector2 = map_to_local(grid_position)
	var new_wall:Wall = wall_packed.instantiate()
	new_wall.set_parameters(wall_position)
	add_child(new_wall)
	
func make_belt(grid_position: Vector2i, direction: float):
	var belt_position: Vector2 = map_to_local(grid_position)
	var new_machine:Belt = belt_packed.instantiate()
	new_machine.set_parameters(belt_position, direction)
	machines.append(new_machine)
	add_child(new_machine)
	
func make_dispenser(grid_position: Vector2i, dispense_type: int):
	var dispenser_position: Vector2 = map_to_local(grid_position)
	var new_dispenser:Dispenser = dispenser_packed.instantiate()
	new_dispenser.set_parameters(dispenser_position, dispense_type)
	add_child(new_dispenser)
	machines.append(new_dispenser)
	new_dispenser.dispense.connect(_on_dispense)
	
func make_combiner(grid_position: Vector2i, offset_dir: Vector2i):
	
	var combiner_position: Vector2 = map_to_local(grid_position)
	var new_combiner = combiner_packed.instantiate()
	var direction = 0
	if(offset_dir.y == 0):
		direction = PI/2
	new_combiner.set_parameters(Vector2(combiner_position) + offset_dir*Consts.GRID_SIZE/2, direction)
	add_child(new_combiner)
	machines.append(new_combiner)
	
	
	
	
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

func reset_to_start_of_run():
	delete_assemblies()
	cycle = -1
	
	assemblies = starting_assemblies
	starting_assemblies = []
	
	for assembly:Assembly in assemblies:
		add_child(assembly)
		assembly.deleted.connect(_on_assembly_delete)
		
	for machine:Machine in machines:
		machine.reset()
	
	_on_stop_object_pressed()


func delete_assemblies():
	
	# The assembly delete method removes it from the assemblies array
	# (indirectly), so we need to duplicate the array first.
	for assembly:Assembly in assemblies.duplicate():
		assembly.delete()
		

func delete_machines():
	for machine:Machine in machines:
		remove_child(machine)
		
	machines = []

	
func delete_walls():
	var child_list:Array[Node] = get_children()
	
	for child:Node in child_list:
		if child is Wall:
			remove_child(child)
	
		
func remove_dispenser_type(widget_type: int):
	
	for machine:Machine in machines.duplicate():
		if machine is Dispenser and machine.get_type() == widget_type:
			machines.erase(machine)
			remove_child(machine)
	
	pass

#endregion


#region button callbacks

func _on_assembly_delete(deleted: Assembly):
	assemblies.erase(deleted)
	
func _on_dispense(loc: Vector2, init_widget_type: int):
	make_widget(local_to_map(loc), init_widget_type)

func _on_up_conveyor_select_pressed():
	conveyor_direction = Consts.UP
	click_mode = MODIFY_FLOOR


func _on_down_conveyor_select_pressed():
	conveyor_direction = Consts.DOWN
	click_mode = MODIFY_FLOOR


func _on_left_conveyor_select_pressed():
	conveyor_direction = Consts.LEFT
	click_mode = MODIFY_FLOOR


func _on_right_conveyor_select_pressed():
	conveyor_direction = Consts.RIGHT
	click_mode = MODIFY_FLOOR


func _on_place_object_pressed():
	click_mode = PLACE_THING
	widget_type = 1
	
	
func _on_place_widget2_pressed():
	click_mode = PLACE_THING
	widget_type = 2

func _on_place_dispenser_pressed():
	click_mode = PLACE_DISPENSER
	widget_type = 1
	pass # Replace with function body.


func _on_place_dispenser2_pressed():
	click_mode = PLACE_DISPENSER
	widget_type = 2
	pass # Replace with function body.
	
func _on_place_combiner_pressed():
	click_mode = PLACE_COMBINER

func _on_place_wall_pressed():
	click_mode = PLACE_WALL
	
	

func _on_place_track_pressed():
	click_mode = PLACE_TRACK


func _on_move_object_pressed():
	simulation_started.emit()
	unhighlight_all()
	run = true


func _on_stop_object_pressed():
	run = false
	

func _on_reset_pressed():
	
	reset_to_start_of_run()
		


func _on_clear_pressed():
	delete_assemblies()
	delete_machines()
	delete_walls()
	reset_to_start_of_run()


#endregion



#region Debug helpers

func setup_debug_objects():
	
	goal = goal_packed.instantiate()
	goal.set_parameters(map_to_local(Vector2i(10,2)))
	goal.add_widget(Vector2(0,0), 2)
	goal.add_widget(Vector2(-2*Consts.GRID_SIZE,0), 2)
	goal.add_widget(Vector2(Consts.GRID_SIZE,0), 1)
	goal.add_widget(Vector2(-Consts.GRID_SIZE,0), 1)
	

	

#endregion

