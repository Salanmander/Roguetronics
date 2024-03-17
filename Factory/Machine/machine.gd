extends Area2D
class_name Machine


# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)

var last_cycle:float

var nearby_widgets:Array[Widget]




func set_machine_parameters(init_position: Vector2, init_layer: int):
	position = init_position
	nearby_widgets = [] 
	last_cycle = 0
	z_index = init_layer
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
		
	# Connecting signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	pass # Replace with function body.


func run_to(_cycle:float):
	pass
	
	
func _on_area_entered(entering:Area2D):
	if entering is Widget:
		nearby_widgets.append(entering)
		entering.deleted.connect(_on_nearby_widget_deleted)
	pass
	
func _on_area_exited(exiting:Area2D):
	if exiting is Widget:
		nearby_widgets.erase(exiting)
		exiting.deleted.disconnect(_on_nearby_widget_deleted)
	pass
	
func _on_nearby_widget_deleted(deleted_widget:Widget):
	nearby_widgets.erase(deleted_widget)

