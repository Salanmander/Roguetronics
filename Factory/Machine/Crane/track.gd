extends Node2D
class_name Track

const track_color = Color(0.5, 0.5, 0.5)
const arrow_color = Color(0.9, 0.9, 0)

var points:Array[Vector2i] = []
var looped:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func click_at(grid_loc:Vector2i):
	points.append(grid_loc)
	make_lines()
	
func drag_to(grid_loc:Vector2i):
	
	# First case: drag is still in the same square, do nothing
	if grid_loc == points[-1]:
		return
		
	# Second case: drag goes backwards, pop the last point
	if points.size() >= 2 and grid_loc == points[-2]:
		points.remove_at(points.size() - 1)
		make_lines()
		return
	
	# Temp default
	points.append(grid_loc)
	make_lines()
		
		
func make_lines():
	# Delete all child nodes
	var children = get_children()
	for node in children:
		# TODO: Use debug inspector to look for orphaned nodes, see
		# if this is leaving a bunch of stuff in memory, also see if I can
		# just queue_free without removing
		node.queue_free()
		
	# Make a square at the beginning
	var start = Polygon2D.new()
	var half_square = Vector2(0.5, 0.5) * Consts.GRID_SIZE
	var offset = points[0] * Consts.GRID_SIZE + half_square
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
			shape_points = [points[i-1] * Consts.GRID_SIZE + half_square,
							points[i] * Consts.GRID_SIZE + half_square]
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
		offset = points[-1] * Consts.GRID_SIZE + half_square
		shape_points = [Vector2(-30, 30) + offset,
							Vector2(-30, -30) + offset,
							Vector2(30, -30) + offset,
							Vector2(30, 30) + offset]
		end.polygon = PackedVector2Array(shape_points)
		end.color = track_color
		add_child(end)
	
	
	
	
		
