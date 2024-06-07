extends Area2D
class_name Machine



var last_cycle:float

var nearby_widgets:Array[Widget]

var highlight_line:Line2D




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


func run_to(_cycle:float):
	pass
	
func reset():
	last_cycle = 0
	
func highlight():
	highlight_line.visible = true
	
func unhighlight():
	highlight_line.visible = false
	
	
	
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

