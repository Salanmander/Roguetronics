extends Machine
class_name Track

# This makes a Track be a kind of Area2D, and it really doesn't need that
# functionality. We're okay with it, though, because this lets Tracks
# be tracked as a kind of Machine by the FactoryFloor.

const track_color = Color(0.5, 0.5, 0.5)
const arrow_color = Color(0.9, 0.9, 0)

var points: Array[Vector2i] = []
var looped: bool = false

# Keys are crane objects, values are indices
var cranes: Dictionary = {}

const LAYER:int = 5


signal crashed()


#region constructors
# Called when the node enters the scene tree for the first time.

static func create(grid_loc: Vector2i) -> Track:
	var new_track: Track = Track.new()
	new_track.set_parameters(grid_loc)
	return new_track
	
static func create_from_save(save_dict: Dictionary) -> Track:
	var new_track: Track = Track.new()
	new_track.load_from_save(save_dict)
	return new_track

	
func set_parameters(grid_loc: Vector2i):
	points.append(grid_loc)
	make_lines()
	

func _ready():
	z_index = LAYER
	pass # Replace with function body.

	
#endregion


#region overriddenMachineMethods

		
func highlight(grid_loc: Vector2i) -> Machine:
	var ind: int = points.find(grid_loc)
	
	# Check index of each crane by getting it from the dictionary,
	# and then checking the value stored at that key.
	for crane: Crane in cranes:
		if cranes[crane] == ind:
			crane.highlight(grid_loc)
			return crane
	
	return null

func unhighlight() -> void:
	for crane: Crane in cranes:
		crane.unhighlight()
		
func run_to(cycle: float) -> void:
	for crane: Crane in cranes:
		crane.run_to(cycle)
	
func reset() -> void:
	for crane: Crane in cranes:
		crane.reset()

#endregion

#region mouse controls

# Returns true if the track has been successfully grabbed
func can_grab_at(grid_loc: Vector2i) -> bool:
	return grid_loc == points[-1]

# Returns true if the location is on any part of the track.
func exists_at(grid_loc: Vector2i) -> bool:
	return grid_loc in points
	
func drag_to(grid_loc: Vector2i):
	
	# First case: drag is still in the same square, do nothing
	if grid_loc == points[-1]:
		pass
		
	# Second case: drag goes backwards, pop the last point
	elif points.size() >= 2 and grid_loc == points[-2]:
		points.remove_at(points.size() - 1)
		looped = false
		make_lines()
	
	# Third case: drag goes to the very first point, close the loop
	elif grid_loc == points[0]:
		points.append(grid_loc)
		looped = true
		make_lines()
		
	# Fourth case: drag intersects any other point, or track is looped, do nothing
	elif looped or grid_loc in points:
		pass
	
	# TODO: Fifth case: mouse went too far, go into directional mode
	
	
	# Default, extend the track
	else:
		points.append(grid_loc)
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
	crane.crashed.connect(_on_crane_crashed.bind(crane))
	
	# Set the index of the initial location of the crane
	var grid_loc: Vector2i = Util.floor_local_to_map(crane.position)
	var ind: int = points.find(grid_loc)
	crane.set_initial_index(ind)
	cranes[crane] = ind
	

func _on_crane_move(offset: int, crane: Crane):
	var current_ind: int = cranes[crane]
	var target_ind: int = current_ind
	var offset_ind: int = current_ind + offset
	if offset_ind < points.size() and offset_ind >= 0:
		target_ind = offset_ind
		
	if looped:
		if offset_ind >= points.size():
			target_ind = offset_ind - points.size() + 1
		if offset_ind < 0:
			target_ind = offset_ind + points.size() - 1
			
		
	var target_point = points[target_ind]
	
	# update crane location
	cranes[crane] = target_ind
	
	crane.set_target(Util.floor_map_to_local(target_point))
	pass

	
func has_crane_at(loc: Vector2i) -> bool:
	for crane: Crane in cranes:
		if points[cranes[crane]] == loc:
			return true
	
	return false
	
func _on_crane_reset(track_index: int, crane: Crane):
	var new_pos: Vector2 = Util.floor_map_to_local(points[track_index])
	crane.teleport_to(new_pos)
	cranes[crane] = track_index
	
func _on_crane_crashed(_crane: Crane):
	crashed.emit()
	

#endregion


		
		
func make_lines():
	# Delete all child lines and polygons and sprites
	var children = get_children()
	for node in children:
		if node is Line2D or node is Polygon2D or node is Sprite2D:
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
		
	# Add sprites on top where appropriate
	if points.size() >= 2:
		# Track sprites are identified with a direction code:
		#
		#     7 0 1
		#      \|/
		#     6-*-2
		#      /|\
		#     5 4 3
		#
		# Code is 2 digits giving direction that the track extends.
		# Order is always smaller number first.
		# The second part is "x" if the track is a terminal.
		for i in range(0, points.size()):
			var start_loc: Vector2 = Util.floor_map_to_local(points[i])
			var dir_letters: Array[String] = ["x", "x"]
			for ind_diff in [-1, 1]:
				var new_ind: int = i + ind_diff
				if(new_ind < 0 or new_ind >= points.size()):
					continue
				var next_loc: Vector2 = Util.floor_map_to_local(points[i + ind_diff])
				var diff = next_loc - start_loc
				var dir_letter = "x"
				if(diff.x == 0 and diff.y > 0):
					dir_letter = "4"
				if(diff.x == 0 and diff.y < 0):
					dir_letter = "0"
				if(diff.x > 0 and diff.y == 0):
					dir_letter = "2"
				if(diff.x < 0 and diff.y == 0):
					dir_letter = "6"
				
				# (ind_diff + 1)/2 turns [-1, 1] into [0,1]
				dir_letters[(ind_diff+1)/2] = dir_letter
			
			dir_letters.sort()
			var texture_path = dir_letters[0] + dir_letters[1]
			texture_path = "res://Factory/Machine/Crane/Track" + texture_path + ".png"
				
			if( FileAccess.file_exists(texture_path) ):
				var terminal = Sprite2D.new()
				terminal.texture = load(texture_path)
				terminal.position = start_loc
				
				add_child(terminal)
			
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {} 
	save_dict["type"] = "track"
	save_dict["points"] = var_to_str(points)
	save_dict["looped"] = looped
	
	var crane_dicts: Array = []
	for crane: Crane in cranes:
		crane_dicts.append(crane.get_save_dict())
	save_dict["cranes"] = crane_dicts
	return save_dict
	
func load_from_save(save_dict: Dictionary) -> void:
	points = str_to_var(save_dict["points"])
	looped = save_dict["looped"]
	
	for crane_dict: Dictionary in save_dict["cranes"]:
		var new_crane: Crane = Crane.create_from_save(crane_dict)
		add_crane(new_crane)
		
	make_lines()

#endregion
	
	
	
		
