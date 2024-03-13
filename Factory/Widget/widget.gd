extends Area2D
class_name Widget

var speed:Vector2 = Vector2(0,0)
var tex:Texture = load("res://Factory/Widget/widget.png")

signal nudged(delta: Vector2)
signal combined(this_widget:Widget, combined_by:Combiner)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = tex
	pass # Replace with function body.


	
func nudge(delta: Vector2):
	nudged.emit(delta)

func combine(combiner:Combiner):
	combined.emit(self, combiner)
	
