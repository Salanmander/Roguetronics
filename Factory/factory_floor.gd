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

var selected:int = FLOOR_TILE
var selected_variant:int = CONVEYOR_UP_VARIANT

var click_mode:int = NONE

var assembly_packed:PackedScene = load("res://Factory/Assembly/assembly.tscn")
var assemblies:Array[Assembly]


var belt_packed:PackedScene = load("res://Factory/Machine/Belt/belt.tscn")
var machines:Array[Machine]
var conveyor_direction:float

var run:bool = false
var cycle_time:float = 1 # Number of seconds for one cycle
var cycle:float = 0 # Current cycle count

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(25):
		for y in range(15):
			#pass
			set_cell(FLOOR_LAYER, Vector2i(x, y), FLOOR_TILE, Vector2i(0,0))
	
	assemblies = []
	machines = []
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if run:
		cycle += delta / cycle_time
		for machine:Machine in machines:
			machine.run_to(cycle)
			
		for assembly:Assembly in assemblies:
			assembly.run_to(cycle)
	pass

	
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		event = make_input_local(event)
		var grid_loc:Vector2i = local_to_map(event.position)
		var thing_position:Vector2i = grid_loc * tile_set.tile_size
		thing_position = thing_position + (tile_set.tile_size/2)
		if(click_mode == MODIFY_FLOOR):
			remove_machines(grid_loc)
			var new_machine:Belt = belt_packed.instantiate()
			new_machine.set_parameters(thing_position, conveyor_direction)
			machines.append(new_machine)
			add_child(new_machine)
			
		elif(click_mode == PLACE_THING):
			var new_assembly = assembly_packed.instantiate()
			new_assembly.position = thing_position
			add_child(new_assembly)
			assemblies.append(new_assembly)
				
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
				var new_assembly = assembly_packed.instantiate()
				new_assembly.position = thing_position + Vector2i(wall_at_min_dist)
				add_child(new_assembly)
				assemblies.append(new_assembly)
				
			pass
		pass
	pass
	
func remove_machines(grid_loc: Vector2i):
	var i:int = machines.size() - 1
	while i >= 0:
		if local_to_map(machines[i].position) == grid_loc:
			remove_child(machines[i])
			machines.remove_at(i)
		i -= 1
	pass

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

func _on_place_combiner_pressed():
	click_mode = PLACE_COMBINER


func _on_move_object_pressed():
	run = true


func _on_stop_object_pressed():
	run = false

