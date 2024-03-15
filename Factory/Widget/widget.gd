extends Area2D
class_name Widget

var speed:Vector2 = Vector2(0,0)
var tex:Texture
var type:int = -1

signal nudged(delta: Vector2)
signal combined(this_widget:Widget, combined_by:Combiner)
signal overlap_detected_with(other_assembly: Assembly)

func set_parameters(init_position:Vector2, widget_type:int):
	position = init_position
	set_type(widget_type)

# Called when the node enters the scene tree for the first time.
func _ready():
	if type == -1:
		type = 1
		tex = load("res://Factory/Widget/widget.png")
		$Sprite2D.texture = tex
	pass # Replace with function body.
	
func set_type(widget_type: int):
	type = widget_type
	if type == 1:
		tex = load("res://Factory/Widget/widget.png")
	elif type == 2:
		tex = load("res://Factory/Widget/widget2.png")
	
	
	$Sprite2D.texture = tex
	

func tell_overlaps_to_check_assembly(parent: Assembly):
	var overlaps:Array[Area2D] = get_overlapping_areas()
	for other in overlaps:
		if other is Widget:
			other.check_overlap_with(parent)
	pass
	
func check_overlap_with(other_assembly: Assembly):
	overlap_detected_with.emit(other_assembly)
	pass
		


	
func nudge(delta: Vector2):
	nudged.emit(delta)

func combine(combiner:Combiner):
	combined.emit(self, combiner)
	
