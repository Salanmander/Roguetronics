extends TileMapLayer


signal assembly_changed(new_assembly: Assembly)

# Creates an Assembly object out of the things currently displayed in the
# grid
func get_assembly() -> Assembly:
	var assembly: Assembly = Assembly.create(Vector2(Consts.GRID_SIZE/2, Consts.GRID_SIZE/2))
	
	# Add widgets. This may result in an assembly with non-standard
	# placement if there are empty rows/colums and the top/left
	for pos: Vector2i in get_used_cells():
		assembly.add_widget(pos*Consts.GRID_SIZE, get_cell_source_id(pos))
		
	return assembly


func set_widget(widget_pos: Vector2, type: int) -> void:
	var grid_loc: Vector2i = local_to_map(widget_pos)
	set_cell(grid_loc, type, Vector2i(0,0))
	if(type == -1):
		var lines_to_remove: Array[Line2D]
		for child: Node in get_children():
			if(child is Line2D):
				for point in child.points:
					if( local_to_map(point) == grid_loc):
						lines_to_remove.append(child)
						
		for line in lines_to_remove:
			line.queue_free()
			remove_child(line)
	assembly_changed.emit(get_assembly())
	
func create_link(click_pos) -> void:
	var grid_loc: Vector2i = local_to_map(click_pos)
	if(get_cell_source_id(grid_loc) == -1):
		return
	
	
	var thing_position: Vector2i = map_to_local(grid_loc)
	
	var TOP = Vector2(0, -1)
	var RIGHT = Vector2(1, 0)
	var BOTTOM = Vector2(0, 1)
	var LEFT = Vector2(-1, 0)
	
	var directions: Array[Vector2] = [TOP, RIGHT, BOTTOM, LEFT]
	var min_dist: float = Consts.GRID_SIZE
	var dir_of_min_dist: Vector2i
	
	for dir in directions:
		var edge_spot: Vector2 = dir*Consts.GRID_SIZE/2.0
		var click_spot: Vector2 = click_pos - thing_position*1.0
		click_spot = click_spot.project(dir)
		
		var dist: float = click_spot.distance_to(edge_spot)
		if dist < min_dist:
			min_dist = dist
			dir_of_min_dist = dir
		
	
	if min_dist < Consts.GRID_SIZE/4: 
		var new_line: Line2D = Line2D.new()
		if(get_cell_source_id(grid_loc + dir_of_min_dist) == -1):
			return
		
		# Change the other point to be relative to the origin.
		var p2: Vector2 = thing_position*1.0 + dir_of_min_dist*Consts.GRID_SIZE
		
		# The first one in the list is always the origin point
		new_line.points = PackedVector2Array([thing_position, p2])
		new_line.default_color = Color(0.15, 0.5, 0.8, 1)
		add_child(new_line)
		assembly_changed.emit(get_assembly())
