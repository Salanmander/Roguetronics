extends Area2D
class_name Widget

var speed:Vector2 = Vector2(0,0)
var tex:Texture
var type:int = -1

var parent_assembly:Assembly


# Contains nearby areas that are *not* part of the same Assembly
var nearby_areas:Array[Area2D]



signal nudged(delta: Vector2)
signal combined(this_widget:Widget, combined_by:Combiner)
signal deleted(this_widget:Widget)
signal overlap_detected_with(other_assembly: Assembly)


# 3x3 array. Contains 1 if the widget can move in that direction this cycle,
# -1 if not, 0 if not certain. This is set by
# the assembly, and includes information from the whole
# assembly.
var mobility:Array[Array]

func _init():
	mobility = [[0, 0, 0],
				[0, 0, 0],
				[0, 0, 0]]

func set_parameters(init_position:Vector2, widget_type:int):
	position = init_position
	set_type(widget_type)

	
func record_parent(new_parent:Assembly):
	parent_assembly = new_parent
	


# Called when the node enters the scene tree for the first time.
func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
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
	

#region Mobility

func reset_mobility():
	mobility = [[0, 0, 0],
				[0, 0, 0],
				[0, 0, 0]]

# This method only checks for the response from a single
# nearby area in the same direction as the questioned direction.
# Can return true, false, or a signal which will be emitted if
# the blocking area finds it can't move.
func can_move_local(dir: Vector2i):
	for area:Area2D in nearby_areas:
		var should_check = false
		if area is Widget:
			should_check = true
		if area is Wall:
			should_check = true
		
		if not should_check:
			continue
		
		# See if the direction to the global position of the nearby
		# widget is about the same as the questioned direction.
		# This might need modification depending on how widget
		# interactions change.
		var to_area = (area.global_position - self.global_position)
		if not abs(to_area.angle_to(dir)) < 0.05:
			continue
			
		# Whatever the area in the way says, that's what we return
		return area.can_move(dir)
		
	# If there is no area in the way, return true
	return true 
	
func can_move(dir: Vector2i):
	match mobility[dir[0]][dir[1]]:
		-1: return false
		1: return true
		0: return parent_assembly.blocked
		
func set_assembly_can_move(assembly_mobility: Array):
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			mobility[x][y] = assembly_mobility[x][y]

#endregion


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
	


func _on_area_entered(entering:Area2D):
	if entering is Wall:
		nearby_areas.append(entering)
	elif entering is Widget:
		if entering.parent_assembly != self.parent_assembly:
			nearby_areas.append(entering)
			entering.deleted.connect(_on_nearby_widget_deleted)
	pass
	
func _on_area_exited(exiting:Area2D):
	if exiting is Wall:
		nearby_areas.erase(exiting)
	elif exiting is Widget:
		if exiting in nearby_areas:
			nearby_areas.erase(exiting)
			exiting.deleted.disconnect(_on_nearby_widget_deleted)
	pass
	
func _on_nearby_widget_deleted(deleted_widget:Widget):
	nearby_areas.erase(deleted_widget)
	
