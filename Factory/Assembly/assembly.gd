extends Node2D
class_name Assembly

var widgets:Array[Widget]
var nudges:Array[Vector2]


var widget_packed:PackedScene = load("res://Factory/Widget/widget.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	widgets = []
	nudges = []
	
	var wid1 = widget_packed.instantiate()
	var wid2 = widget_packed.instantiate()
	wid2.position = Vector2(1, 0) * Consts.GRID_SIZE
	
	add_widget(wid1)
	add_widget(wid2)
	pass # Replace with function body.
	
func run_to(new_cycle:float):
	var dLeft:float = 0
	var dRight:float = 0
	var dDown:float = 0
	var dUp:float = 0
	for nudge in nudges:
		var x:float = nudge.x
		var y:float = nudge.y
		if x > 0 && x > dRight:
			dRight = x
		if x < 0 && x < dLeft:
			dLeft = x
		if y > 0 && y > dDown:
			dDown = y
		if y < 0 && y < dUp:
			dUp = y
			
	var dx = dRight + dLeft
	var dy = dDown + dUp
	
	position += Vector2(dx, dy)
	
	nudges = []
	pass


func add_widget(new_widget:Widget):
	add_child(new_widget)
	widgets.append(new_widget)
	new_widget.nudged.connect(_on_widget_nudged)
	pass
	
func _on_widget_nudged(delta:Vector2):
	nudges.append(delta)
	pass
