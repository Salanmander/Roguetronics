extends Machine
class_name Depot

static var LAYER: int = 0

static var recv_packed = load("res://Factory/Machine/Depot/depot.tscn")

# TODO: make create function, based on call in factory_floor
# check whether init and ready need to call super (or be deleted)

static func create(pos: Vector2) -> Depot:
	var new_depot: Depot = recv_packed.instantiate()
	new_depot.position = pos
	return new_depot


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$Goal.add_widget(Vector2(0, 0), 1)
	#$Goal.add_widget(Vector2(0, Consts.GRID_SIZE), 1)
	update_background_size()
	pass # Replace with function body.


func update_background_size() -> void:
	var grid_size: Vector2i = $Goal.get_grid_size()
	$DepotBackground.set_grid_size(grid_size)
	var sqr: int = Consts.GRID_SIZE
	var bottom: int = (grid_size.y+0.5)*sqr
	var right: int = (grid_size.x+0.5)*sqr
	var highlight_points: Array[Vector2] = [Vector2(-sqr/2, -sqr/2),
											Vector2(-sqr/2, bottom),
											Vector2(bottom, right),
											Vector2(right, -sqr/2),
											]
	highlight_line.points = PackedVector2Array(highlight_points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
