extends Node2D
class_name Goal

var plan:Assembly

var copies_made: int = 0
var copies_needed: int = 3
signal completed()

var LAYER = 0

#region constructors
static func create(init_position: Vector2) -> Goal:
	var new_goal = Goal.new()
	new_goal.set_parameters(init_position)
	return new_goal
	
# See also: get_save_dict
static func create_from_save(save_dict: Dictionary) -> Goal:
	var new_goal: Goal = Goal.new()
	new_goal.load_save_dict(save_dict)
	return new_goal
	
func set_plan(new_plan: Assembly) -> void:
	plan = new_plan
	plan.affected_by_machines = false
	plan.set_monitorable(false)
	add_child(plan)
	plan.perfect_overlap.connect(_on_perfect_overlap)
	

func set_parameters(init_position:Vector2):
	var new_plan: Assembly = Assembly.create(init_position)
	set_plan(new_plan)
	
#endregion



# Called when the node enters the scene tree for the first time.
func _ready():
	# Filter to make the goal transparent
	modulate = Color(1, 1, 1, 0.5)
	
# Called when the factory resets.
func reset() -> void:
	copies_made = 0
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["needed"] = copies_needed
	save_dict["plan"] = plan.get_save_dict()
	return save_dict
	
func load_save_dict(save_dict: Dictionary) -> void:
	copies_needed = save_dict["needed"]
	var plan: Assembly = Assembly.create_from_save(save_dict["plan"])
	set_plan(plan)
	
	


#endregion
	
func set_goal_position(new_position: Vector2):
	plan.set_plan_position(new_position)
	
	
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
	copies_made += 1
	if(copies_made >= copies_needed):
		completed.emit()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
