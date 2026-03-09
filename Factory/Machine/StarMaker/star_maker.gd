extends Machine
class_name StarMaker


static var star_packed: PackedScene = load("res://Factory/Machine/StarMaker/star_maker.tscn")

const LAYER: int = 0

#region constructors

static func create(init_position: Vector2) -> StarMaker:
	var new_star: StarMaker = star_packed.instantiate()
	new_star.set_parameters(init_position)
	return new_star
	
	
static func create_from_save(save_dict: Dictionary) -> StarMaker:
	var new_star: StarMaker = star_packed.instantiate()
	new_star.load_from_save(save_dict)
	return new_star


func set_parameters(init_position: Vector2) -> void:
	set_machine_parameters(init_position, LAYER)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	$DormantSprite.visible = true;
	$ActivatedSprite.visible = false;
	
#endregion


func run_to(cycle: float) -> void:
	
	var cycle_fraction = fmod(cycle, 1)
	
	# When this is the first move of every fifth cycle
	if cycle - last_cycle >= cycle_fraction:
		if int(cycle) % 5 == 1:
			$ActivatedSprite.visible = true
			$DormantSprite.visible = false
			for widget: Widget in nearby_widgets:
				widget.add_star()
	
	# Show activation for 0.3 cycles.
	if cycle_fraction > 0.3:
		$ActivatedSprite.visible = false
		$DormantSprite.visible = true
		
	
		
	last_cycle = cycle
	
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["type"] = "star"
	save_dict["pos"] = var_to_str(position)
	return save_dict
	
func load_from_save(save_dict: Dictionary) -> void:
	set_parameters(str_to_var(save_dict["pos"]))

#endregion
