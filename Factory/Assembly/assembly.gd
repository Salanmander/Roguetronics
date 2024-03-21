extends Node2D
class_name Assembly

var widgets:Array[Widget]
var nudges:Array[Vector2]
var affected_by_machines:bool
var queued_combine_widget:Widget

var last_cycle:float

const LAYER = 1


var widget_packed:PackedScene = load("res://Factory/Widget/widget.tscn")

signal deleted(this_assembly:Assembly)
signal perfect_overlap(other_assembly: Assembly)

func _init():
	widgets = []
	nudges = []
	last_cycle = 0
	z_index = LAYER
	affected_by_machines = true
	
func set_parameters(init_position: Vector2):
	position = init_position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Puts position at the middle of a grid square.
# Is passing in the TileMap a good idea? I don't know!
func snap_to_grid(grid:TileMap):
	position = grid.map_to_local( grid.local_to_map(position))
	
	
func run_to(cycle:float):
	
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
	
	#var cycle_fraction = fmod(cycle, 1)
	#if cycle - last_cycle >= cycle_fraction:
		#var printStr:String = str(widgets.size(), ": locations: ")
		#for widget:Widget in widgets:
			#printStr = str(printStr, "(", widget.position.x, ", ", widget.position.y, ")")
		#print(printStr)
	#last_cycle = cycle
	pass

func add_widget(relative_position:Vector2, widget_type: int):
	var new_widget:Widget = widget_packed.instantiate()
	new_widget.set_parameters(relative_position, widget_type)
	add_widget_object(new_widget)
	pass

func add_widget_object(new_widget:Widget):
	add_child(new_widget)
	new_widget.record_parent(self)
	widgets.append(new_widget)
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.combined.connect(_on_widget_combined)
	new_widget.overlap_detected_with.connect(_on_overlap_detected)
	pass
	
func add_widget_from_other(new_widget:Widget, _other:Assembly):
	var keep_global_transform:bool = true
	new_widget.reparent(self, keep_global_transform)
	new_widget.record_parent(self)
	widgets.append(new_widget)
	new_widget.nudged.disconnect(_other._on_widget_nudged)
	new_widget.combined.disconnect(_other._on_widget_combined)
	new_widget.overlap_detected_with.disconnect(_other._on_overlap_detected)
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.combined.connect(_on_widget_combined)
	new_widget.overlap_detected_with.connect(_on_overlap_detected)
	
func get_widgets() -> Array[Widget]:
	return widgets.duplicate()

# TODO: There has *got* to be a better way to do this
func check_for_any_perfect_overlap():
	for widget:Widget in widgets:
		widget.tell_overlaps_to_check_assembly(self)
	pass
	
func check_perfect_overlap_with(other: Assembly):
	if other == self:
		return
	if(widgets.size() != other.widgets.size()):
		return
	
	for widget in widgets:
		var loc:Vector2 = position + widget.position
		if !other.has_widget_at_position(loc, widget.type):
			return
	
	# We have the same number of widgets, and have gone through and
	# found we have the same type in the same locations
	found_perfect_overlap_with(other)
	other.found_perfect_overlap_with(self)
	pass
	
func found_perfect_overlap_with(other: Assembly):
	perfect_overlap.emit(other)
	pass
	
func has_widget_at_position(loc: Vector2, type: int) -> bool:
	for widget in widgets:
		var this_loc:Vector2 = position + widget.position
		if(this_loc.is_equal_approx(loc) && widget.type == type):
			return true
	return false
	
func _on_widget_nudged(delta:Vector2):
	if(affected_by_machines):
		nudges.append(delta)
	pass

func _on_widget_combined(widget:Widget, combiner:Combiner):
	var group_name:String = str("combining_by_",combiner.idString)
	var combining_assemblies:Array[Node] = get_tree().get_nodes_in_group(group_name)
	if combining_assemblies.size() == 1 && combining_assemblies[0] is Assembly:
		var other_assembly:Assembly = combining_assemblies[0]
		if other_assembly == self:
			return
		other_assembly.combine_with(self, widget)
		
	else:
		add_to_group(group_name)
		queued_combine_widget = widget
		combiner.drop.connect(_on_combiner_drop)
		
	pass
	
func combine_with(other: Assembly, _connect_point: Widget):
	assert(queued_combine_widget != null, "Error: Combine was initiated without connection point being set")
	
	var to_add:Array[Widget] = other.get_widgets()
	for widget in to_add:
		add_widget_from_other(widget, other)
	
	other.delete()
		
	pass

func delete():
	deleted.emit(self)
	queue_free()
	
func delete_widgets():
	for widget:Widget in widgets:
		widget.deleted.emit(widget)
	
func _on_combiner_drop(combiner:Combiner):
	combiner.drop.disconnect(_on_combiner_drop)
	var group_name:String = str("combining_by_",combiner.idString)
	remove_from_group(group_name)
	queued_combine_widget = null
	
func _on_overlap_detected(other_assembly: Assembly):
	check_perfect_overlap_with(other_assembly)
	
	pass
