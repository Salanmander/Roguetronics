extends Area2D
class_name Widget

var speed:Vector2 = Vector2(0,0)
var tex:Texture = load("res://Factory/Widget/widget.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = tex
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func move_to(new_position: Vector2):
	position = new_position
	
