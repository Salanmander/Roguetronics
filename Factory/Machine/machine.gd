extends Area2D
class_name Machine



var last_cycle: float

var nearby_widgets: Array[Widget]

var highlight_line: Line2D


static func create_from_save(save_dict: Dictionary) -> Machine:
	var type = save_dict["type"]
	if type == "belt":
		return Belt.create_from_save(save_dict)
	if type == "dispenser":
		return Dispenser.create_from_save(save_dict)
	if type == "combiner":
		return Combiner.create_from_save(save_dict)
	if type == "track":
		return Track.create_from_save(save_dict)
	if type == "crane":
		return Crane.create_from_save(save_dict)
	
	assert(false, "tried to load machine with invalid type")
	return null

func set_machine_parameters(init_position: Vector2, init_layer: int):
	position = init_position
	nearby_widgets = [] 
	last_cycle = 0
	z_index = init_layer
	monitorable = false
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
		
	# Connecting signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	highlight_line = Line2D.new()
	var highlight_points:Array[Vector2] = [Vector2(-64, -64),
										   Vector2(-64, 64),
										   Vector2(64, 64),
										   Vector2(64, -64)]
	highlight_line.points = PackedVector2Array(highlight_points)
	highlight_line.closed = true
	highlight_line.visible = false
	
	add_child(highlight_line)
	
	pass # Replace with function body.


func run_to(_cycle: float):
	pass
	
func reset():
	last_cycle = 0


# Some machines override this to use the grid location, and may return false.
# Those are included here to be able to override with the same input/output types.
func highlight(_grid_loc: Vector2i) -> Machine:
	highlight_line.visible = true
	return self
	
func unhighlight():
	highlight_line.visible = false
	
	
	
func _on_area_entered(entering: Area2D):
	if entering is Widget:
		nearby_widgets.append(entering)
		entering.deleted.connect(_on_nearby_widget_deleted)
	pass
	
func _on_area_exited(exiting: Area2D):
	if exiting is Widget:
		nearby_widgets.erase(exiting)
		exiting.deleted.disconnect(_on_nearby_widget_deleted)
	pass
	
func _on_nearby_widget_deleted(deleted_widget: Widget):
	nearby_widgets.erase(deleted_widget)
