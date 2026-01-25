extends Area2D
class_name Wall


static var wall_packed: PackedScene = load("res://Factory/Wall/wall.tscn")


#region constructors

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
static func create(init_position: Vector2) -> Wall:
	var new_wall: Wall = wall_packed.instantiate()
	new_wall.set_parameters(init_position)
	return new_wall
	
static func create_from_save(save_dict: Dictionary) -> Wall:
	var new_wall: Wall = wall_packed.instantiate()
	new_wall.load_save_dict(save_dict)
	return new_wall
	

func set_parameters(init_position: Vector2):
	position = init_position
	
#endregion

# Walls need a can_move method that takes a direction, because that's how
# it gets called, but they always return false.
func can_move(_dir: Vector2i):
	return false
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["pos"] = var_to_str(position)
	return save_dict
	
func load_save_dict(save_dict: Dictionary):
	set_parameters(str_to_var(save_dict["pos"]))

#endregion
