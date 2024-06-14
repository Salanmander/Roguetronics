extends Node2D
class_name Track

const track_color = Color(0.5, 0.5, 0.5)
const arrow_color = Color(0.9, 0.9, 0)

var points:Array[Vector2i] = []
var looped:bool = false

var cranes:Array[Crane] = []
var next_cycle_cranes:Array[Crane] = []

const LAYER:int = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	z_index = LAYER
	pass # Replace with function body.
	
func set_parameters(grid_loc:Vector2i):
	points.append(grid_loc)
	cranes.append(null)
	next_cycle_cranes.append(null)
	make_lines()

	

#region mouse controls

# Returns true if the track has been successfully grabbed
func can_grab_at(grid_loc:Vector2i) -> bool:
	return grid_loc == points[-1]

# Returns true if the location is on any part of the track.
func exists_at(grid_loc:Vector2i) -> bool:
	return grid_loc in points
	
func drag_to(grid_loc:Vector2i):
	
	# First case: drag is still in the same square, do nothing
	if grid_loc == points[-1]:
		pass
		
	# Second case: drag goes backwards, pop the last point
	elif points.size() >= 2 and grid_loc == points[-2]:
		points.remove_at(points.size() - 1)
		cranes.remove_at(cranes.size() - 1)
		next_cycle_cranes.remove_at(cranes.size() - 1)
		looped = false
		make_lines()
	
	# Third case: drag goes to the very first point, close the loop
	elif grid_loc == points[0]:
		points.append(grid_loc)
		cranes.append(null)
		next_cycle_cranes.append(null)
		looped = true
		make_lines()
		
	# Fourth case: drag intersects any other point, or track is looped, do nothing
	elif looped or grid_loc in points:
		pass
	
	# TODO: Fifth case: mouse went too far, go into directional mode
	
	
	# Default, extend the track
	else:
		points.append(grid_loc)
		cranes.append(null)
		next_cycle_cranes.append(null)
		make_lines()

#endregion

#region Crane handling

# Adds a crane. It should already have been positioned, and that
# position will be used to determine where on the track it is.
func add_crane(crane: Crane):
	add_child(crane)
	
	# Connect signals from the crane to this
	crane.move_triggered.connect(_on_crane_move.bind(crane))
	crane.reset_triggered.connect(_on_crane_reset.bind(crane))
	
	# Set the index of the initial location of the crane
	var grid_loc: Vector2i = Util.floor_local_to_map(crane.position)
	var ind: int = points.find(grid_loc)
	crane.set_initial_index(ind)
	cranes[ind] = crane
	

func _on_crane_move(offset: int, crane: Crane):
	var current_ind: int = cranes.find(crane)
	var target_ind: int = current_ind
	var offset_ind: int = current_ind + offset
	if offset_ind < points.size():
		target_ind = offset_ind
		
	if looped:
		if offset_ind >= points.size():
			target_ind = offset_ind - points.size() + 1
		if offset_ind < 0:
			target_ind = offset_ind + points.size() - 1
			
		
	var target_point = points[target_ind]
	
	# Move crane into the next frame list, and remove it from this one
	next_cycle_cranes[target_ind] = crane
	cranes[current_ind] = null
	
	crane.set_target(Util.floor_map_to_local(target_point))
	pass
	
# This is needed to update the crane array after *all* the cranes have moved
func update_crane_locations():
	# Move all cranes to the same space in next_frame if they haven't
	# been messed with this frame
	for i in range(cranes.size()):
		if cranes[i] == null:
			continue
		
		next_cycle_cranes[i] = cranes[i]
		cranes[i] = null
	
	var temp = cranes
	cranes = next_cycle_cranes
	next_cycle_cranes = temp
	
func has_crane_at(loc: Vector2i) -> bool:
	for i in range(points.size()):
		if cranes[i] == null:
			continue
		
		if loc == points[i]:
			return true
	
	return false
	
func _on_crane_reset(track_index: int, crane: Crane):
	var new_pos:Vector2 = Util.floor_map_to_local(points[track_index])
	crane.teleport_to(new_pos)
	var old_index = cranes.find(crane)
	cranes[old_index] = null
	cranes[track_index] = crane

#endregion
		
		
func make_lines():
	# Delete all child lines and polygons
	var children = get_children()
	for node in children:
		if node is Line2D or node is Polygon2D:
			node.queue_free()
		
	
	# Make a square at the beginning
	var start = Polygon2D.new()
	var offset = Util.floor_map_to_local(points[0])
	var shape_points = [Vector2(-30, 30) + offset,
						Vector2(-30, -30) + offset,
						Vector2(30, -30) + offset,
						Vector2(30, 30) + offset]
	start.polygon = PackedVector2Array(shape_points)
	start.color = track_color
	add_child(start)
	
	if points.size() >= 2:
		for i in range(1, points.size()):
			var segment = Line2D.new()
			shape_points = [Util.floor_map_to_local(points[i-1]),
							Util.floor_map_to_local(points[i])]
			segment.points = PackedVector2Array(shape_points)
			segment.default_color = track_color
			add_child(segment)
			
			# Make arrow
			var arrow = Polygon2D.new()
			arrow.position = shape_points[0].lerp(shape_points[1], 0.5)
			arrow.rotation = shape_points[0].angle_to_point(shape_points[1])
			shape_points = [Vector2(-15, -15),
							Vector2(15, 0),
							Vector2(-15, 15)]
			arrow.polygon = PackedVector2Array(shape_points)
			arrow.color = arrow_color
			add_child(arrow)
		
		var end = Polygon2D.new()
		offset = Util.floor_map_to_local(points[-1])
		shape_points = [Vector2(-30, 30) + offset,
							Vector2(-30, -30) + offset,
							Vector2(30, -30) + offset,
							Vector2(30, 30) + offset]
		end.polygon = PackedVector2Array(shape_points)
		end.color = track_color
		add_child(end)
	
	
	
	
		
