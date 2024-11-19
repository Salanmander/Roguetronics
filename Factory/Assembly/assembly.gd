extends Node2D
class_name Assembly

var widgets: Array[Widget]
var links: Array[Line2D]
var nudges: Array[Vector2]
var forced_positions: Array[Vector2]
var affected_by_machines: bool
var monitorable: bool
var queued_combine_widget: Widget

var layer_change_this_update: int


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
	last_cycle = 0
	z_index = LAYER
	affected_by_machines = true
	monitorable = true
	layer_change_this_update = -1
	
func set_parameters(init_position: Vector2):
	position = init_position
	
func set_monitorable(new_monitorable: bool):
	monitorable = new_monitorable
	for widget:Widget in widgets:
		widget.monitorable = monitorable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Puts position at the middle of a grid square if it's close enough
func snap_to_grid():
	
	var center_position = Util.floor_map_to_local( Util.floor_local_to_map(position))
	if abs(position.x - center_position.x) < Consts.GRID_SIZE/16:
		position.x = center_position.x
	
	if abs(position.y - center_position.y) < Consts.GRID_SIZE/16:
		position.y = center_position.y
	
#region Mobility

# Attempts to move the assembly the given amount
func check_and_move(delta: Vector2):
	
	if can_move(Vector2(delta.x, 0)):
		move(Vector2(delta.x, 0))
	
	if can_move(Vector2(0, delta.y)):
		move(Vector2(0,delta.y))
		
		
func can_move(delta: Vector2, ignore_nudges: bool = false) -> bool:
	
	var forced:bool = forced_positions.size() > 0
	
	
	if forced:
		var new_pos: Vector2 = forced_positions[0]
		# We don't need to check other forced positions right now.
		# They'll get checked later when this moves, and will cause a crash
		# at that time. And we're okay with crashes being after some motion has
		# happened.
		
		var forced_delta: Vector2 = new_pos - position
		print(delta)
		var x_okay: bool = is_equal_approx(delta.x, 0) or forced_delta.x/delta.x > 0.99
		var y_okay: bool = is_equal_approx(delta.y, 0) or forced_delta.y/delta.y > 0.99
		
		var temp1 = is_equal_approx(delta.x, 0)
		var temp2 = forced_delta.x/delta.x > 0.99
		
		if not(x_okay and y_okay):
			return false
	
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
	
	
	# Assemblies get run after all the machines go, so we can
	# reset this every frame.
	layer_change_this_update = -1
	
	
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
	
	add_widget_helper(new_widget)
	pass
	
func add_widget_from_other(new_widget: Widget, other: Assembly):
	var keep_global_transform: bool = true
	new_widget.reparent_custom(self, keep_global_transform)
	
	new_widget.nudged.disconnect(other._on_widget_nudged)
	new_widget.forced_to.disconnect(other._on_widget_forced_to)
	new_widget.combined.disconnect(other._on_widget_combined)
	new_widget.layer_changed.disconnect(other._on_widget_layer_changed)
	
	add_widget_helper(new_widget)
	
	
# Adds a line to the assembly as a link. One of the points will be at 0,0.
# The second point will always be in the positive x direction if possible.
# If there's no difference, it will be in the positive y direction.
#      x
#     /
#    O---x
#    |\
#    | x
#    x
func add_link(p1: Vector2, p2: Vector2):
	# Figure out which point counts as the origin of this link
	var origin: Vector2
	var other: Vector2
	if(p1.x < p2.x):
		origin = p1
		other = p2
	elif(p1.x == p2.x and p1.y < p2.y):
		origin = p1
		other = p2
	else:
		origin = p2
		other = p1
	
	var new_line: Line2D = Line2D.new()
	
	# Set the location of the new line based on the location of the origin point
	new_line.position = origin
	
	# Change the other point to be relative to the origin.
	other = other - origin
	
	# The first one in the list is always the origin point
	new_line.points = PackedVector2Array([Vector2(0, 0), other])
	new_line.default_color = Color(0.15, 0.5, 0.8, 1)
	add_child(new_line)
	links.append(new_line)
	
func add_widget_helper(new_widget: Widget):
	new_widget.monitorable = monitorable
	widgets.append(new_widget)
	
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.forced_to.connect(_on_widget_forced_to)
	new_widget.combined.connect(_on_widget_combined)
	new_widget.layer_changed.connect(_on_widget_layer_changed)
	
	if(new_widget.position.x < 0):
		var shift_amount = -new_widget.position.x
		
		# Shift assembly in the same direction that the new widget is
		position.x -= shift_amount
		
		var shift_vector: Vector2 = Vector2(shift_amount, 0)
		
		# Shift all widgets and links in the opposite direction
		for widget: Widget in widgets:
			widget.shift_by(shift_vector)
			
		for link: Line2D in links:
			var new1: Vector2 = link.points[0] + shift_vector
			var new2: Vector2 = link.points[1] + shift_vector
			link.points = PackedVector2Array([new1, new2])
			
			
	if(new_widget.position.y < 0):
		var shift_amount = -new_widget.position.y
		
		# Shift assembly in the same direction that the new widget is
		position.y -= shift_amount
		
		
		# Shift all widgets and links in the opposite direction
		var shift_vector: Vector2 = Vector2(0, shift_amount)
		for widget: Widget in widgets:
			widget.shift_by(shift_vector)
			
		for link: Line2D in links:
			var new1: Vector2 = link.points[0] + shift_vector
			var new2: Vector2 = link.points[1] + shift_vector
			link.points = PackedVector2Array([new1, new2])
	
func get_widgets() -> Array[Widget]:
	return widgets.duplicate()
	
func get_links() -> Array[Line2D]:
	return links.duplicate()


#region match checking
	
func check_for_overlap_with(others: Array[Assembly]):
	for other: Assembly in others:
		if other.position.is_equal_approx(position) and matches(other):
			perfect_overlap.emit(other)
	pass


func matches(other: Assembly):
	
	var other_widgets: Array[Widget] = other.get_widgets()
	
	if widgets.size() != other_widgets.size():
		return false
		
		
	var other_links: Array[Line2D] = other.get_links()
	
	if links.size() != other_links.size():
		return false
		
		
	# Check that all widgets match
	
	for widget: Widget in widgets:
		var found: bool = false
		
		for other_widget: Widget in other_widgets:
			
			if widget.position.is_equal_approx(other_widget.position) and \
			   widget.get_type() == other_widget.get_type():
				found = true
				break
		
		if not found:
			return false
		
	
	# Check that all links match
	
	for link: Line2D in links:
		var found: bool = false
		
		# Links always have exactly two points. The first one is
		# at (0, 0) relative to the link's position. We care about
		# the position and the second point.
		var point2: Vector2 = link.points[1]
		for other_link: Line2D in other_links:
			var o_point2: Vector2 = other_link.points[1]
			
			if (link.position.is_equal_approx(other_link.position) and \
				point2.is_equal_approx(o_point2)):
				found = true
				break
		
		if not found:
			return false
	
	return true
	

#endregion
			
		
	
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
	
func _on_widget_layer_changed(new_layer: int):
	if not affected_by_machines:
		return
	
	# BUG: A crane can lift an assembly while another crane is grabbing
	# it at a lower level.
	# Probably just need to have each crane broadcast the layer change
	# every frame, unfortunately.
	if layer_change_this_update != -1:
		if layer_change_this_update != new_layer:
			crashed.emit()
	else:
		layer_change_this_update = new_layer
		for widget:Widget in widgets:
			widget.set_layer(new_layer)

# new_position is the position that *this assembly* must have to put
# the widget in the right place
func _on_widget_forced_to(new_position: Vector2):
	if(affected_by_machines):
		forced_positions.append(new_position)



#region Combining and deleting

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
	for link in other.get_links():
		link.reparent(self, keep_global_transform)
		links.append(link)
			
		
		
	# connect_point is now in this assembly, so positions can be used directly
	var p1: Vector2 = queued_combine_widget.position
	var p2: Vector2 = connect_point.position
	
	# add_link will re-normalize so that one of the points of the
	# line is at (0, 0)
	add_link(p1, p2)
	
		
	
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
	
