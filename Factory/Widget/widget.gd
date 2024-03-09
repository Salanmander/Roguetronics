extends Node2D
class_name Widget

var speed:Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position + speed
	pass
	
func run():
	speed = Vector2(1,0)
	
func stop():
	speed = Vector2(0,0)
