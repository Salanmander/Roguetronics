extends Node2D
class_name Machine

var held:Widget
var direction:float


func set_parameters(position: Vector2, direction: float):
	self.position = position
	self.direction = direction
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	var child:Sprite2D = $Sprite2D
	child.texture = load("res://Factory/icon.png")
	child.rotation = direction
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
