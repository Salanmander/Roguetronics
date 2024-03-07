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

var thing_to_move:Polygon2D

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(25):
		for y in range(15):
			#pass
			set_cell(FLOOR_LAYER, Vector2i(x, y), FLOOR_TILE, Vector2i(0,0))
	
	thing_to_move = Polygon2D.new()
	var vertices:Array[Vector2] = [Vector2(-35, 0), Vector2(0, 50), Vector2(35, 0), Vector2(0, -50)]
	thing_to_move.polygon = PackedVector2Array(vertices)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

	
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		event = make_input_local(event)
		var grid_loc:Vector2i = local_to_map(event.position)
		if(click_mode == MODIFY_FLOOR):
			set_cell(FLOOR_LAYER, grid_loc, selected, Vector2i(0,0), selected_variant)
		elif(click_mode == PLACE_THING):
			var thing_position:Vector2i = grid_loc * tile_set.tile_size
			thing_position = thing_position + (tile_set.tile_size/2)
			thing_to_move.position = thing_position
			if (not thing_to_move.get_tree()):
				add_child(thing_to_move)
	pass

func _on_up_conveyor_select_pressed():
	selected = CONVEYOR_TILE
	selected_variant = CONVEYOR_UP_VARIANT
	click_mode = MODIFY_FLOOR


func _on_down_conveyor_select_pressed():
	selected = CONVEYOR_TILE
	selected_variant = CONVEYOR_DOWN_VARIANT
	click_mode = MODIFY_FLOOR


func _on_left_conveyor_select_pressed():
	selected = CONVEYOR_TILE
	selected_variant = CONVEYOR_LEFT_VARIANT
	click_mode = MODIFY_FLOOR


func _on_right_conveyor_select_pressed():
	selected = CONVEYOR_TILE
	selected_variant = CONVEYOR_RIGHT_VARIANT
	click_mode = MODIFY_FLOOR


func _on_place_object_pressed():
	click_mode = PLACE_THING
