extends Node2D
class_name Goal

var assembly_packed = load("res://Factory/Assembly/assembly.tscn")
var plan:Assembly

var LAYER = 0

func set_parameters(init_position:Vector2):
	plan = assembly_packed.instantiate()
	plan.set_parameters(init_position)
	plan.affected_by_machines = false
	plan.set_monitorable(false)
	add_child(plan)
	plan.perfect_overlap.connect(_on_perfect_overlap)



# Called when the node enters the scene tree for the first time.
func _ready():
	# Filter to make the goal transparent
	modulate = Color(1, 1, 1, 0.5)
	
	
func add_widget(init_position:Vector2, widget_type:int):
	plan.add_widget(init_position, widget_type)

func add_widget_object(new_widget:Widget):
	plan.add_widget_object(new_widget)
	
func add_link(p1: Vector2, p2: Vector2):
	plan.add_link(p1, p2)
	
func check_against(others: Array[Assembly]):
	plan.check_for_overlap_with(others)
	
func _on_perfect_overlap(other:Assembly):
	other.delete_widgets()
	other.delete()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
