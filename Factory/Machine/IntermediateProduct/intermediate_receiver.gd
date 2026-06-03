extends Machine
class_name IntermediateReceiver


func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Goal.add_widget(Vector2(0, 0), 1)
	$Goal.add_widget(Vector2(0, Consts.GRID_SIZE), 1)
	update_background_size()
	pass # Replace with function body.


func update_background_size() -> void:
	var grid_size: Vector2i = $Goal.get_grid_size()
	print(grid_size)
	$IntermediateBackground.set_grid_size(grid_size)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
