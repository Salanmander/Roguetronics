extends Machine 
class_name Belt

# Inherited fields
#  nearby_widgets:Array[Widget]
#  last_cycle:float


# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)
var left_texture = load("res://Factory/Machine/Belt/Left.png")
var right_texture = load("res://Factory/Machine/Belt/Right.png")
var up_texture = load("res://Factory/Machine/Belt/Up.png")
var down_texture = load("res://Factory/Machine/Belt/Down.png")

var held_widget:Widget
var direction:float
var arm_offset:Vector2

var last_arm_offset:Vector2


var DEBUG_GRABBER:bool = false
var grabber_display:Sprite2D

const LAYER:int = 0


func set_parameters(init_position: Vector2, init_direction: float):
	set_machine_parameters(init_position, LAYER)
	direction = init_direction
	arm_offset = Vector2(0,0)
	last_arm_offset = Vector2(0,0)
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	
	var child:Sprite2D = $Sprite2D
	if(direction == 0):
		child.texture = up_texture
	elif direction == PI/2:
		child.texture = right_texture
	elif direction == PI:
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


func run_to(cycle:float):
	var cycle_fraction = fmod(cycle, 1)
	
	# When this is the first move of a cycle
	if cycle - last_cycle >= cycle_fraction:
		drop()
		grab()
		last_arm_offset = Vector2(0,0)
		
	arm_offset = Vector2(0,-1).rotated(direction) * Consts.GRID_SIZE * cycle_fraction
	
	# If we're holding something
	if held_widget:
		held_widget.nudge(arm_offset - last_arm_offset)
		
	if DEBUG_GRABBER:
		grabber_display.position = arm_offset
		
	last_cycle = cycle
	last_arm_offset = arm_offset
		
	
	pass
	
func drop():
	held_widget = null
	
func grab():
	if held_widget == null && nearby_widgets.size() > 0:
		held_widget = nearby_widgets[0]
	pass
	

