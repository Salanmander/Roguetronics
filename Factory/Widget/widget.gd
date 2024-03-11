extends Area2D
class_name Widget

var speed:Vector2 = Vector2(0,0)
var tex:Texture = load("res://Factory/Widget/widget.png")

signal nudged(delta: Vector2)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = tex
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func nudge(delta: Vector2):
	nudged.emit(delta)
	
