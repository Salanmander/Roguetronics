extends Area2D
class_name Wall


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_parameters(init_position:Vector2):
	position = init_position

# Walls need a can_move method that takes a direction, because that's how
# it gets called, but they always return false.
func can_move(_dir: Vector2i):
	return false
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
