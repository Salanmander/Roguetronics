extends Area2D
class_name Machine


# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)

var last_cycle:float

var nearby_widgets:Array[Node2D]




func set_machine_parameters(init_position: Vector2, init_layer: int):
	position = init_position
	nearby_widgets = [] 
	last_cycle = 0
	z_index = init_layer
	monitorable = false
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
		
	
	pass # Replace with function body.


func run_to(_cycle:float):
	nearby_widgets = get_overlapping_bodies()
	pass
	
	

