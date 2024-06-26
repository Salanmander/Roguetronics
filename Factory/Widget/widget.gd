extends Area2D
class_name Widget

var speed: Vector2 = Vector2(0,0)
var tex: Texture
var type: int = -1

var parent_assembly: Assembly


# Contains nearby areas that are *not* part of the same Assembly
var nearby_areas: Array[Area2D]



signal nudged(delta: Vector2)
signal combined(this_widget:Widget, combined_by:Combiner)
signal deleted(this_widget:Widget)
signal overlap_detected_with(other_assembly: Assembly)
signal forced_to(assembly_pos: Vector2)


# 3x3 array. Contains 1 if the widget can move in that direction this cycle,
# -1 if not, 0 if not certain. This is set by
# the assembly, and includes information from the whole
# assembly.
var mobility:Array[Array]

func _init():
	mobility = [[0, 0, 0],
				[0, 0, 0],
				[0, 0, 0]]

func set_parameters(init_position: Vector2, widget_type: int):
	position = init_position
	set_type(widget_type)

	
func record_parent(new_parent: Assembly):
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

func overlaps_can_move(ignore_nudges: bool = false) -> bool:
	var this_shape: Shape2D = shape_owner_get_shape(0,0)
	var this_transform: Transform2D = get_global_transform()

	for area: Area2D in nearby_areas:
		var other_shape: Shape2D = area.shape_owner_get_shape(0,0)
		var other_transform: Transform2D = area.get_global_transform()
		
		var contacts = this_shape.collide_and_get_contacts(this_transform, other_shape, other_transform)
		
		if(contacts.size() < 2):
			continue
			
		if area is Wall:
			return false
		elif area is Widget:
			
			var other_assembly = area.parent_assembly
			if not other_assembly.can_move(contacts[0] - contacts[1], ignore_nudges):
				return false
			pass
	
	return true
	
# This does not check if overlaps can move, it just moves them. Checking
# should be done before calling this method.
func push_overlaps():
	var this_shape: Shape2D = shape_owner_get_shape(0,0)
	var this_transform: Transform2D = get_global_transform()

	for area: Area2D in nearby_areas:
		var other_shape: Shape2D = area.shape_owner_get_shape(0,0)
		var other_transform: Transform2D = area.get_global_transform()
		
		var contacts = this_shape.collide_and_get_contacts(this_transform, other_shape, other_transform)
		
		if(contacts.size() < 2):
			continue
			
		if area is Widget:
			var other_assembly = area.parent_assembly
			other_assembly.move(contacts[0] - contacts[1])
			
	
	pass


#endregion


func tell_overlaps_to_check_assembly(parent: Assembly):
	var overlaps: Array[Area2D] = get_overlapping_areas()
	for other in overlaps:
		if other is Widget:
			other.check_overlap_with(parent)
	pass
	
func check_overlap_with(other_assembly: Assembly):
	overlap_detected_with.emit(other_assembly)
	pass
	
	


	
func nudge(delta: Vector2):
	nudged.emit(delta)

# The position it emits is the position that the *assembly* will
# need to move its base location to
func force_to(new_pos: Vector2):
	var assembly_pos: Vector2 = new_pos - position
	forced_to.emit(assembly_pos)

func combine(combiner:Combiner):
	combined.emit(self, combiner)
	
# BUG: There are still some problems with signal connections 
# while reparenting, I think
func reparent_custom(new_parent: Assembly, keep_global_transform:bool ):
	
	# Storing the nearby areas state is necessary because reparenting
	# seems to trigger *leaving* signals on this area, but not *entering*
	# ones. (Other areas seem to do just fine keeping track of this one.)
	var store_nearby_areas = nearby_areas.duplicate()
	record_parent(new_parent)
	reparent(new_parent, keep_global_transform)
	nearby_areas = store_nearby_areas
	
	var to_remove: Array[Area2D] = []
	for area: Area2D in nearby_areas:
		if area is Widget:
			if area.parent_assembly == self.parent_assembly:
				to_remove.append(area)
			else:
				area.deleted.connect(_on_nearby_widget_deleted)
				
	for area: Area2D in to_remove:
		nearby_areas.erase(area)
				
	
	


func _on_area_entered(entering: Area2D):
	if entering is Wall:
		nearby_areas.append(entering)
	elif entering is Widget:
		if entering.parent_assembly != self.parent_assembly:
			nearby_areas.append(entering)
			entering.deleted.connect(_on_nearby_widget_deleted)
	pass
	
func _on_area_exited(exiting: Area2D):
	if exiting is Wall:
		nearby_areas.erase(exiting)
	elif exiting is Widget:
		if exiting in nearby_areas:
			nearby_areas.erase(exiting)
			# BUG: sometimes this tries to erase a connection that
			# doesn't exist. Probably to do with combining widgets again.
			exiting.deleted.disconnect(_on_nearby_widget_deleted)
	pass
	
func _on_nearby_widget_deleted(deleted_widget: Widget):
	nearby_areas.erase(deleted_widget)
	
