extends Button

var fact = preload("res://Factory/factory.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(_go)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _go():
	get_tree().change_scene_to_packed(fact)
