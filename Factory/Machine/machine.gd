extends Node2D
class_name Machine

var held:Widget
var direction:float

# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)
var left_texture = load("res://Factory/Machine/Left.png")
var right_texture = load("res://Factory/Machine/Right.png")
var up_texture = load("res://Factory/Machine/Up.png")
var down_texture = load("res://Factory/Machine/Down.png")


func set_parameters(position: Vector2, direction: float):
	self.position = position
	self.direction = direction
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	var child:Sprite2D = $Sprite2D
	if(direction == 0):
		child.texture = up_texture
	elif direction == PI/2:
		child.texture = right_texture
	elif direction == PI:
		child.texture = down_texture
	else:
		child.texture = left_texture
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
