extends Machine
class_name Depot

static var LAYER: int = 0

static var recv_packed = load("res://Factory/Machine/Depot/depot.tscn")

signal completed()


static func create(pos: Vector2) -> Depot:
	var new_depot: Depot = recv_packed.instantiate()
	new_depot.position = pos
	return new_depot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_background_size()
	var sqr: int = Consts.GRID_SIZE
	$DepotBackground.position = Vector2(-0.5*sqr, -0.5*sqr)
	highlight_line.position = Vector2(-0.5*sqr, -0.5*sqr)
	
	# Connect signals from the goal
	$Goal.completed.connect(_on_requirement_met)


func run_to(cycle: float) -> void:
	# This runs if it's the first update of the cycle
	var cycle_fraction = fmod(cycle, 1)
	if cycle - last_cycle >= cycle_fraction:
		var nearby_assemblies: Array[Assembly] = []
		for widget: Widget in nearby_widgets:
			if( not widget.parent_assembly in nearby_assemblies ):
				nearby_assemblies.append(widget.parent_assembly)
		$Goal.check_against(nearby_assemblies)
	last_cycle = cycle
	
func reset() -> void:
	super()
	$Goal.reset()

func update_background_size() -> void:
	var grid_size: Vector2i = $Goal.get_grid_size()
	grid_size = Vector2i(max(1, grid_size.x), max(1, grid_size.y))
	var sqr: int = Consts.GRID_SIZE
	var bottom: int = grid_size.y*sqr
	var right: int = grid_size.x*sqr
	var highlight_points: Array[Vector2] = [Vector2(0, 0),
											Vector2(0, bottom),
											Vector2(right, bottom),
											Vector2(right, 0),
											]
	highlight_line.points = PackedVector2Array(highlight_points)
	
	$Shape.shape.size = Vector2(right, bottom)-Vector2(2,2)
	$Shape.position = (grid_size-Vector2i(1,1))*sqr/2
	$DepotBackground.region_rect = Rect2(0, 0, right, bottom)


# pos is local to the Depot
func contains_point(pos: Vector2) -> bool:
	return $DepotBackground.region_rect.has_point(pos - $DepotBackground.position)

func _on_target_assembly_changed(new_assembly: Assembly) -> void:
	$Goal.set_plan(new_assembly)
	update_background_size()
	
func _on_required_number_changed(new_count: int) -> void:
	$Goal.copies_needed = new_count
	
func _on_requirement_met() -> void:
	completed.emit()
	pass
