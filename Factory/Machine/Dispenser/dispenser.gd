extends Machine 
class_name Dispenser

# Inherited fields
#  nearby_widgets:Array[Widget]
#  last_cycle:float


# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)
var type:int = -1


const LAYER = 3

signal dispense(widget_position: Vector2, widget_type: int)



# Direction should be either 0 or PI/2
func set_parameters(init_position: Vector2, widget_type: int):
	set_machine_parameters(init_position, LAYER)
	type = widget_type
	var tex
	if type == 1:
		tex = load("res://Factory/Machine/Dispenser/dispenser.png")
	elif type == 2:
		tex = load("res://Factory/Machine/Dispenser/dispenser2.png")
	
	$Sprite2D.texture = tex
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	
	if type == -1:
		type = 1
		var tex = load("res://Factory/Widget/widget.png")
		$Sprite2D.texture = tex
		
	
	pass # Replace with function body.


func run_to(cycle:float):
	var cycle_fraction = fmod(cycle, 1)
	
	# When this is the first move of a cycle
	if cycle - last_cycle >= cycle_fraction:
		if(nearby_widgets.size() == 0):
			dispense.emit(position, type)
	
		
		
	last_cycle = cycle
		
	
	pass


