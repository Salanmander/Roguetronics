extends Node2D
class_name Assembly

var widgets:Array[Widget]
var nudges:Array[Vector2]
var affected_by_machines:bool
var monitorable:bool
var queued_combine_widget:Widget

# 3x3 array. Contains 1 if the assembly can move in that direction
# this cycle, -1 if not, 0 if unchecked. Index is the direction, so
# negative indices are used, and [0][0] is the entry for not
# moving (unused)
var mobility:Array[Array]

var last_cycle:float

const LAYER = 1


var widget_packed:PackedScene = load("res://Factory/Widget/widget.tscn")

signal deleted(this_assembly:Assembly)
signal perfect_overlap(other_assembly: Assembly)
signal blocked(direction: Vector2i)
signal nudged(direction: Vector2)

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
func snap_to_grid(grid:TileMap):
	position = grid.map_to_local( grid.local_to_map(position))
	

#region Mobility

# TODO: disconnect mobility signals before checking each frame
# TODO: add movement signal connections for nudging

# Indicate that mobility needs to be checked again.
func reset_mobility():
	mobility = [[0, 0, 0],
				[0, 0, 0],
				[0, 0, 0]]
	
	# Disconnect mobility signals
	var blocked_connections:Array = blocked.get_connections()
	for conn in blocked_connections:
		blocked.disconnect(conn.callable)
	var nudged_connections:Array = nudged.get_connections()
	for conn in nudged_connections:
		nudged.disconnect(conn.callable)
		
	for widget:Widget in widgets:
		widget.reset_mobility()

# Sets the mobility array
func check_mobility():
	
	# I don't think this is necessary? Might be needed to prevent
	# infinite looping.
	#if checked_mobility:
		#return
		
		
	# Checking each direction
	for x:int in [-1, 0, 1]:
		for y:int in [-1, 0, 1]:
			if x == 0 && y == 0:
				continue
			
			var all_okay: bool = true
			for widget:Widget in widgets:
				# Response can be true, false, or a signal
				# True means the widget is certain the local surroundings don't
				# prevent it from moving.
				# False means the widget is certain it can't move that way
				# A signal is a signal that will be emitted, with a direction
				# parameter, if the widget is blocked by something that didn't
				# realize it when this was checked.
				var response = widget.can_move_local(Vector2i(x, y))
				if response is Signal:
					all_okay = false
					
					# Makes the callback be a call to _on_blocked with one input based
					# on what direction this is currently checking, and one input based
					# on the signal parameter
					response.connect(func(dir: Vector2i): _on_blocked(Vector2i(x, y), dir))
					
							
					pass
				elif not response:
					all_okay = false
					record_blockage(Vector2i(x, y))
					break
					
			# If we get through all the widgets and none report a blockage
			# or potential blockage, record the direction as definitely okay
			if all_okay:
				mobility[x][y] = 1
				
			
			pass
	
	for widget:Widget in widgets:
		# Passes the nudged signal of this assembly to each widget,
		# to have it connect it to nearby assemblies.
		# It might get connected multiple times, but that's okay
		widget.connect_nudged_signals(nudged)
		widget.set_assembly_can_move(mobility)
			
	pass
	
func can_move(direction: Vector2i):
	pass
		

# Called whenever a blockage is seen in a certain direction.
# Needs to check to see if direction has already been blocked,
# and emit a signal iff this is the first time it's been noticed.
# That is to prevent signal infinite loops
func record_blockage(direction: Vector2i):
	if(mobility[direction.x][direction.y] == -1):
		return
	mobility[direction.x][direction.y] = -1
	blocked.emit(direction)
	pass


# Callbacks for when a blocked signal is coming from a particular direction
# If the direction of the signal matches the direction it's coming from, then
# record that direction as blocked if not already.
func _on_blocked(signal_from: Vector2i, blocking_dir: Vector2i):
	if signal_from == blocking_dir:
		record_blockage(blocking_dir)
	pass

#endregion
	
	
func run_to(cycle:float):
	
	var dLeft:float = 0
	var dRight:float = 0
	var dDown:float = 0
	var dUp:float = 0
	for nudge in nudges:
		var x:float = nudge.x
		var y:float = nudge.y
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
	
	if dx > 0 and mobility[1][0] == -1:
		dx = 0
	if dx < 0 and mobility[-1][0] == -1:
		dx = 0
	if dy > 0 and mobility[0][1] == -1:
		dy = 0
	if dy < 0 and mobility[0][-1] == -1:
		dy = 0
	
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
	new_widget.monitorable = monitorable
	widgets.append(new_widget)
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.combined.connect(_on_widget_combined)
	new_widget.overlap_detected_with.connect(_on_overlap_detected)
	pass
	
func add_widget_from_other(new_widget:Widget, other:Assembly):
	var keep_global_transform:bool = true
	new_widget.reparent_custom(self, keep_global_transform)
	new_widget.monitorable = monitorable
	widgets.append(new_widget)
	new_widget.nudged.disconnect(other._on_widget_nudged)
	new_widget.combined.disconnect(other._on_widget_combined)
	new_widget.overlap_detected_with.disconnect(other._on_overlap_detected)
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
	#if other == self:
		#return
	if(widgets.size() != other.widgets.size()):
		return
	
	for widget in widgets:
		var loc:Vector2 = position + widget.position
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
		var this_loc:Vector2 = position + widget.position
		if(this_loc.is_equal_approx(loc) && widget.type == type):
			return true
	return false
	
func _on_widget_nudged(delta:Vector2):
	if(affected_by_machines):
		nudges.append(delta)
		nudged.emit(delta)
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
	for widget:Widget in to_add:
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
