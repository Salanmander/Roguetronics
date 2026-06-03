extends Sprite2D


var LAYER = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(-Consts.GRID_SIZE/2, -Consts.GRID_SIZE/2)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_grid_size(grid_size: Vector2i) -> void:
	var m: int = Consts.GRID_SIZE
	region_rect = Rect2(0, 0, grid_size.x * m, grid_size.y * m)
