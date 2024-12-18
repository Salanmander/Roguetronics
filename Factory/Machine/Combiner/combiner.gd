extends Machine 
class_name Combiner

# Inherited fields
#  nearby_widgets:Array[Widget]
#  last_cycle:float


# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)
var h_texture = load("res://Factory/Machine/Combiner/combiner_H.png")
var v_texture = load("res://Factory/Machine/Combiner/combiner_V.png")

var direction:float

var idString:String

signal drop(combiner: Combiner)

const LAYER = 3



# Direction should be either 0 or PI/2
func set_parameters(init_position: Vector2, direction: float):
	set_machine_parameters(init_position, LAYER)
	idString = str(int(position.x), int(position.y))
	self.direction = direction
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	
	var child:Sprite2D = $Sprite2D
	if is_equal_approx(fmod(direction, PI), 0):
		child.texture = v_texture
		$LeftCollisionShape.position = Vector2(0, -Consts.GRID_SIZE/2)
		$RightCollisionShape.position = Vector2(0, Consts.GRID_SIZE/2)
	else:
		child.texture = h_texture
		$LeftCollisionShape.position = Vector2(-Consts.GRID_SIZE/2, 0)
		$RightCollisionShape.position = Vector2(Consts.GRID_SIZE/2, 0)
	
	pass # Replace with function body.


func run_to(cycle: float):
	var cycle_fraction = fmod(cycle, 1)
	
	# When this is the first move of a cycle
	if cycle - last_cycle >= cycle_fraction:
		
		# If there are two widgets, combine them
		if nearby_widgets.size() == 2:
			#print(str("Combining ", nearby_widgets[0], " and ", nearby_widgets[1]))
			nearby_widgets[0].combine(self)
			nearby_widgets[1].combine(self)
			pass
	
	else:
		drop.emit(self)
		
		
	last_cycle = cycle
		
	
	pass
	
func reset():
	super.reset()
	
	

