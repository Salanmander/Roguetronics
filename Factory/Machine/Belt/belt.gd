extends Machine 
class_name Belt

# Inherited fields
#  nearby_widgets:Array[Widget]
#  last_cycle:float

static var belt_packed: PackedScene = load("res://Factory/Machine/Belt/belt.tscn")

# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)
var left_texture = load("res://Factory/Machine/Belt/Left.png")
var right_texture = load("res://Factory/Machine/Belt/Right.png")
var up_texture = load("res://Factory/Machine/Belt/Up.png")
var down_texture = load("res://Factory/Machine/Belt/Down.png")

var held_widgets: Array[Widget]
var direction: float
var arm_offset: Vector2

var last_arm_offset: Vector2


var DEBUG_GRABBER: bool = false
var grabber_display: Sprite2D

const LAYER:int = 0


#region constructors

static func create(init_position: Vector2, init_direction: float) -> Belt:
	var new_belt = belt_packed.instantiate()
	new_belt.set_parameters(init_position, init_direction)
	return new_belt
	
static func create_from_save(save_dict: Dictionary) -> Belt:
	var new_belt = belt_packed.instantiate()
	new_belt.load_from_save(save_dict)
	return new_belt
	

func set_parameters(init_position: Vector2, init_direction: float) -> void:
	set_machine_parameters(init_position, LAYER)
	direction = init_direction
	arm_offset = Vector2(0,0)
	last_arm_offset = Vector2(0,0)
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	
	var child: Sprite2D = $Sprite2D
	if is_equal_approx(direction, 0):
		child.texture = up_texture
	elif is_equal_approx(direction, PI/2):
		child.texture = right_texture
	elif is_equal_approx(direction, PI):
		child.texture = down_texture
	else:
		child.texture = left_texture
		
	
	#child.scale = Vector2(0,0)
	
	if DEBUG_GRABBER:
		grabber_display = Sprite2D.new()
		grabber_display.texture = up_texture
		grabber_display.scale = Vector2(0.2, 0.2)
		add_child(grabber_display)
		
	
	pass # Replace with function body.

#endregion

func run_to(cycle: float):
	var cycle_fraction = fmod(cycle, 1)
	
	# When this is the first move of a cycle
	if cycle - last_cycle >= cycle_fraction:
		drop()
		grab()
		last_arm_offset = Vector2(0,0)
		
	arm_offset = Vector2(0,-1).rotated(direction) * Consts.GRID_SIZE * cycle_fraction
	
	# If we're holding something
	for widget: Widget in held_widgets:
		if widget in nearby_widgets:
			widget.nudge(arm_offset - last_arm_offset)
		
	if DEBUG_GRABBER:
		grabber_display.position = arm_offset
		
	last_cycle = cycle
	last_arm_offset = arm_offset
		
	
	pass
	
func reset():
	super.reset()
	drop()
	
func drop():
	for widget: Widget in held_widgets:
		widget.deleted.disconnect(_on_widget_deleted)
	held_widgets = []
	
func grab():
	if held_widgets.size() == 0 && nearby_widgets.size() > 0:
		held_widgets = nearby_widgets.duplicate()
		for widget: Widget in held_widgets:
			widget.deleted.connect(_on_widget_deleted)
	pass
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["type"] = "belt"
	save_dict["pos"] = var_to_str(position)
	save_dict["dir"] = direction
	return save_dict
	
func load_from_save(save_dict: Dictionary) -> void:
	set_parameters(str_to_var(save_dict["pos"]), save_dict["dir"])

#endregion
	
func _on_widget_deleted(widget: Widget):
	held_widgets.erase(widget)
	
