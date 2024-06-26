extends Node2D
class_name Assembly

var widgets: Array[Widget]
var nudges: Array[Vector2]
var forced_positions: Array[Vector2]
var affected_by_machines: bool
var monitorable: bool
var queued_combine_widget: Widget

# 3x3 array. Contains 1 if the assembly can move in that direction
# this cycle, -1 if not, 0 if unchecked. Index is the direction, so
# negative indices are used, and [0][0] is the entry for not
# moving (unused)
# TODO: I think this can be gotten rid of
var mobility: Array[Array]

var last_cycle: float

const LAYER = 1

var assembly_packed: PackedScene = load("res://Factory/Assembly/assembly.tscn")
var widget_packed: PackedScene = load("res://Factory/Widget/widget.tscn")

signal deleted(this_assembly: Assembly)
signal perfect_overlap(other_assembly: Assembly)
signal blocked(direction: Vector2i)
signal nudged(delta: Vector2)
signal crashed()

func _init():
	widgets = []
	nudges = []
	mobility = [[0, 0, 0],
				[0, 0, 0],
				[0, 0, 0]]
	last_cycle = 0
	z_index = LAYER
	affected_by_machines = true
	monitorable = true
	
func set_parameters(init_position: Vector2):
	position = init_position
	
func set_monitorable(new_monitorable: bool):
	monitorable = new_monitorable
	for widget:Widget in widgets:
		widget.monitorable = monitorable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Puts position at the middle of a grid square.
# Is passing in the TileMap a good idea? I don't know!
func snap_to_grid(grid: TileMap):
	position = grid.map_to_local( grid.local_to_map(position))
	


	
#region Mobility

# TODO: what should happen if assemblies meet mid-cycle? Suggestion: just
# let them end up misaligned, and make conveyors only push until there is
# no overlap.

# Attempts to move the assembly the given amount
func check_and_move(delta: Vector2):
	
	if can_move(Vector2(delta.x, 0)):
		move(Vector2(delta.x, 0))
	
	if can_move(Vector2(0, delta.y)):
		move(Vector2(0,delta.y))
		
		
func can_move(delta: Vector2, ignore_nudges: bool = false) -> bool:
	
	if not ignore_nudges:
		for nudge: Vector2 in nudges:
			var angle = nudge.angle_to(delta)
			var len_delta = delta.length()
			var len_nudge = nudge.length()
			if (is_equal_approx(angle, PI)) and \
			   (len_delta < len_nudge or is_equal_approx(len_delta, len_nudge) ):
				return false
			pass
	
	position += delta
	
	var can_move: bool = true
	# Tell component widgets to poll now-overlapping areas for mobility
	for widget: Widget in widgets:
		if not widget.overlaps_can_move(ignore_nudges):
			can_move = false
			break
		pass
	
	position -= delta

	return can_move
	
func move(delta: Vector2):
	position += delta
	
	# Tell component widgets to push now-overlapping areas
	for widget: Widget in widgets:
		widget.push_overlaps()
		
func clear_moves():
	forced_positions = []
	nudges = []
	

#endregion
	
func run_to(cycle: float):
	
	var forced:bool = forced_positions.size() > 0
	
	if forced:
		var new_pos: Vector2 = forced_positions[0]
		for pos in forced_positions:
			if not new_pos.is_equal_approx(pos):
				crashed.emit()
		
		var delta: Vector2 = new_pos - position
		var ignore_nudges: bool = true
		if not can_move(delta, ignore_nudges):
			can_move(delta, ignore_nudges)
			crashed.emit()
		
		move(delta)
		
	else:
		var dLeft: float = 0
		var dRight: float = 0
		var dDown: float = 0
		var dUp: float = 0
		for nudge in nudges:
			var x: float = nudge.x
			var y: float = nudge.y
			if x > 0 and x > dRight:
				dRight = x
			if x < 0 and x < dLeft:
				dLeft = x
			if y > 0 and y > dDown:
				dDown = y
			if y < 0 and y < dUp:
				dUp = y
				
		var dx = dRight + dLeft
		var dy = dDown + dUp
		
		#if dx > 0 and mobility[1][0] == -1:
			#dx = 0
		#if dx < 0 and mobility[-1][0] == -1:
			#dx = 0
		#if dy > 0 and mobility[0][1] == -1:
			#dy = 0
		#if dy < 0 and mobility[0][-1] == -1:
			#dy = 0
		
		check_and_move(Vector2(dx, dy))
	
	
	#var cycle_fraction = fmod(cycle, 1)
	#if cycle - last_cycle >= cycle_fraction:
		#var printStr:String = str(widgets.size(), ": locations: ")
		#for widget:Widget in widgets:
			#printStr = str(printStr, "(", widget.position.x, ", ", widget.position.y, ")")
		#print(printStr)
	#last_cycle = cycle
	pass

func add_widget(relative_position: Vector2, widget_type: int):
	var new_widget: Widget = widget_packed.instantiate()
	new_widget.set_parameters(relative_position, widget_type)
	add_widget_object(new_widget)
	pass

func add_widget_object(new_widget: Widget):
	add_child(new_widget)
	new_widget.record_parent(self)
	new_widget.monitorable = monitorable
	widgets.append(new_widget)
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.forced_to.connect(_on_widget_forced_to)
	new_widget.combined.connect(_on_widget_combined)
	new_widget.overlap_detected_with.connect(_on_overlap_detected)
	pass
	
func add_widget_from_other(new_widget: Widget, other: Assembly):
	var keep_global_transform: bool = true
	new_widget.reparent_custom(self, keep_global_transform)
	new_widget.monitorable = monitorable
	widgets.append(new_widget)
	new_widget.nudged.disconnect(other._on_widget_nudged)
	new_widget.forced_to.disconnect(other._on_widget_forced_to)
	new_widget.combined.disconnect(other._on_widget_combined)
	new_widget.overlap_detected_with.disconnect(other._on_overlap_detected)
	
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.forced_to.connect(_on_widget_forced_to)
	new_widget.combined.connect(_on_widget_combined)
	new_widget.overlap_detected_with.connect(_on_overlap_detected)
	
func get_widgets() -> Array[Widget]:
	return widgets.duplicate()

#region Combining and deleting

# TODO: There has *got* to be a better way to do this
func check_for_any_perfect_overlap():
	for widget: Widget in widgets:
		widget.tell_overlaps_to_check_assembly(self)
	pass
	
func check_perfect_overlap_with(other: Assembly):
	#if other == self:
		#return
	if(widgets.size() != other.widgets.size()):
		return
	
	for widget in widgets:
		var loc: Vector2 = position + widget.position
		if not other.has_widget_at_position(loc, widget.type):
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
		var this_loc: Vector2 = position + widget.position
		if(this_loc.is_equal_approx(loc) && widget.type == type):
			return true
	return false
	
func _on_nudged_toward_direction(dir: Vector2, delta: Vector2):
	var angle_between = delta.angle_to(dir)
	if abs(angle_between) > 0.01:
		return
	_on_widget_nudged(delta)
	
func _on_widget_nudged(delta: Vector2):
	if(affected_by_machines):
		nudges.append(delta)
		nudged.emit(delta)
	pass

# new_position is the position that *this assembly* must have to put
# the widget in the right place
func _on_widget_forced_to(new_position: Vector2):
	if(affected_by_machines):
		forced_positions.append(new_position)

func _on_widget_combined(widget: Widget, combiner: Combiner):
	var group_name: String = str("combining_by_",combiner.idString)
	var combining_assemblies: Array[Node] = get_tree().get_nodes_in_group(group_name)
	if combining_assemblies.size() == 1 && combining_assemblies[0] is Assembly:
		var other_assembly: Assembly = combining_assemblies[0]
		if other_assembly == self:
			return
		other_assembly.combine_with(self, widget)
		
	else:
		add_to_group(group_name)
		queued_combine_widget = widget
		combiner.drop.connect(_on_combiner_drop)
		
	pass
	
func combine_with(other: Assembly, connect_point: Widget):
	assert(queued_combine_widget != null, "Error: Combine was initiated without connection point being set")
	
	# Add the other widgets
	var to_add: Array[Widget] = other.get_widgets()
	for widget: Widget in to_add:
		add_widget_from_other(widget, other)
		
	# Add the other lines
	var keep_global_transform: bool = true
	for node in other.get_children():
		if node is Line2D:
			node.reparent(self, keep_global_transform)
			
		
		
	# connect_point is now in this assembly, so positions can be used directly
	var p1: Vector2 = queued_combine_widget.position
	var p2: Vector2 = connect_point.position
	
	var new_line = Line2D.new()
	new_line.points = PackedVector2Array([p1, p2])
	new_line.default_color = Color(0.15, 0.5, 0.8, 1)
	add_child(new_line)
		
	
	other.delete()
		
	pass

func delete():
	deleted.emit(self)
	queue_free()
	
func delete_widgets():
	for widget: Widget in widgets:
		widget.deleted.emit(widget)

#endregion

func clone() -> Assembly:
	var copy = assembly_packed.instantiate()
	copy.position = position;
	copy.monitorable = monitorable;
	
	for widget: Widget in widgets:
		copy.add_widget(widget.position, widget.type)
	
	return copy
	
func _on_combiner_drop(combiner: Combiner):
	combiner.drop.disconnect(_on_combiner_drop)
	var group_name: String = str("combining_by_",combiner.idString)
	remove_from_group(group_name)
	queued_combine_widget = null
	
func _on_overlap_detected(other_assembly: Assembly):
	check_perfect_overlap_with(other_assembly)
	
	pass
