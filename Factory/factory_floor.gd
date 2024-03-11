extends TileMap

# This is a dumb place for notes, but, TODO:
#  make icon for thing to move
#  bring it in, and make button to place, move stop
#  grid align placement
#  have move button move it one square and then stop
#  Have move be conditional based on conveyor

const FLOOR_LAYER = 0

const CONVEYOR_TILE = 4
const CONVEYOR_UP_VARIANT = 0
const CONVEYOR_DOWN_VARIANT = 1
const CONVEYOR_LEFT_VARIANT = 2
const CONVEYOR_RIGHT_VARIANT = 3

const FLOOR_TILE = 5

const NONE = 0
const MODIFY_FLOOR = 1
const PLACE_THING = 2

var selected:int = FLOOR_TILE
var selected_variant:int = CONVEYOR_UP_VARIANT

var click_mode:int = NONE

var widget_packed:PackedScene = load("res://Factory/Widget/widget.tscn")
var thing_to_move:Widget


var machine_packed:PackedScene = load("res://Factory/Machine/machine.tscn")
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
	
	thing_to_move = widget_packed.instantiate()
	machines = []
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if run:
		cycle += delta / cycle_time
		for machine:Machine in machines:
			machine.run_to(cycle)
	pass

	
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		event = make_input_local(event)
		var grid_loc:Vector2i = local_to_map(event.position)
		var thing_position:Vector2i = grid_loc * tile_set.tile_size
		thing_position = thing_position + (tile_set.tile_size/2)
		if(click_mode == MODIFY_FLOOR):
			remove_machines(grid_loc)
			var new_machine:Machine = machine_packed.instantiate()
			new_machine.set_parameters(thing_position, conveyor_direction)
			machines.append(new_machine)
			add_child(new_machine)
			
		elif(click_mode == PLACE_THING):
			
			thing_to_move.position = thing_position
			if (!thing_to_move.is_inside_tree()):
				add_child(thing_to_move)
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


func _on_move_object_pressed():
	run = true


func _on_stop_object_pressed():
	run = false
