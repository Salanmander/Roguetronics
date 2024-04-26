extends TileMap
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

var goal_packed:PackedScene = load("res://Factory/Goal/goal.tscn")
var goal:Goal

var run:bool = false
var cycle_time:float = 1 # Number of seconds for one cycle
var cycle:float = 0 # Current cycle count
var last_cycle:float = 0 # Previous frame cycle count


# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(25):
		for y in range(15):
			#pass
			set_cell(FLOOR_LAYER, Vector2i(x, y), FLOOR_TILE, Vector2i(0,0))
	
	assemblies = []
	machines = []

	setup_debug_objects()
	
	add_child(goal)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _physics_process(delta: float):
	if run:
		cycle += delta / cycle_time
		
		
		# Need to combine before checking mobility
		for machine:Machine in machines:
			if machine is Combiner:
				machine.run_to(cycle)
		
		var cycle_fraction = fmod(cycle, 1)
		if cycle - last_cycle >= cycle_fraction:
			for assembly:Assembly in assemblies:
				assembly.reset_mobility()
			
			# Need to check mobility after resetting all of them,
			# because the mobility check recursively calls it
			# on other assemblies
			for assembly:Assembly in assemblies:
				assembly.check_mobility()
			
			goal.check()
				
		for machine:Machine in machines:
			if !(machine is Combiner):
				machine.run_to(cycle)
			
		for assembly:Assembly in assemblies:
			assembly.run_to(cycle)
			
		
		# This runs if it's the *last* update before the end
		# of the cycle
		if cycle - last_cycle >= (1-cycle_fraction):
			for assembly:Assembly in assemblies:
				assembly.snap_to_grid(self)
			
		last_cycle = cycle
	pass

	
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		event = make_input_local(event)
		var grid_loc:Vector2i = local_to_map(event.position)
		var thing_position:Vector2i = map_to_local(grid_loc)
		if(click_mode == MODIFY_FLOOR):
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
			var wall_at_min_dist:Vector2
			
			for dir in directions:
				var edge_spot:Vector2 = dir*Consts.GRID_SIZE/2.0
				var click_spot:Vector2 = event.position - thing_position*1.0
				click_spot = click_spot.project(dir)
				
				var dist:float = click_spot.distance_to(edge_spot)
				if dist < min_dist:
					min_dist = dist
					wall_at_min_dist = edge_spot
				
			
			if min_dist < Consts.GRID_SIZE/4: 
				make_combiner(grid_loc, wall_at_min_dist)
				
			pass
		elif(click_mode == PLACE_DISPENSER):
			make_dispenser(grid_loc, widget_type)
			
			pass
		elif(click_mode == PLACE_WALL):
			make_wall(grid_loc)
			
			pass
		pass
	pass
	
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
	
func make_belt(grid_position: Vector2i, direction: int):
	var belt_position: Vector2 = map_to_local(grid_position)
	var new_machine:Belt = belt_packed.instantiate()
	new_machine.set_parameters(belt_position, conveyor_direction)
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
	new_combiner.set_parameters(Vector2i(combiner_position) + offset_dir*Consts.GRID_SIZE/2, direction)
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

func _on_assembly_delete(deleted: Assembly):
	assemblies.erase(deleted)
	
func _on_dispense(loc: Vector2, init_widget_type: int):
	make_widget(local_to_map(loc), init_widget_type)

func _on_up_conveyor_select_pressed():
	conveyor_direction = 0
	click_mode = MODIFY_FLOOR


func _on_down_conveyor_select_pressed():
	conveyor_direction = PI
	click_mode = MODIFY_FLOOR


func _on_left_conveyor_select_pressed():
	conveyor_direction = 3*PI/2
	click_mode = MODIFY_FLOOR


func _on_right_conveyor_select_pressed():
	conveyor_direction = PI/2
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


func _on_move_object_pressed():
	run = true


func _on_stop_object_pressed():
	run = false





#region Debug helpers

func setup_debug_objects():
	
	goal = goal_packed.instantiate()
	goal.set_parameters(map_to_local(Vector2i(10,2)))
	goal.add_widget(Vector2(0,0), 2)
	goal.add_widget(Vector2(0,-Consts.GRID_SIZE), 2)
	goal.add_widget(Vector2(Consts.GRID_SIZE,0), 1)
	goal.add_widget(Vector2(-Consts.GRID_SIZE,0), 1)
	
	make_widget(Vector2i(10, 5), 1)
	make_widget(Vector2i(10, 6), 2)
	make_widget(Vector2i(9, 6), 1)
	
	make_combiner(Vector2i(10, 5), Vector2i(0, 1))


func _on_test_pressed():
	Engine.physics_ticks_per_second *= 1.2
	Engine.max_physics_steps_per_frame *= 1.2
	pass # Replace with function body.

#endregion
