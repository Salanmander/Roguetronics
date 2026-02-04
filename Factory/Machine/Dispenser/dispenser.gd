extends Machine 
class_name Dispenser

# Inherited fields
#  nearby_widgets:Array[Widget]
#  last_cycle:float

static var dispenser_packed: PackedScene = load("res://Factory/Machine/Dispenser/dispenser.tscn")

# Could be refactored at some point so that it doesn't need to load these
# textures multiple times. (Does that already get optimized out?)
var type: int = -1

var cycle_spacing: int = 4
var last_spawn_cycle: int = 0


const LAYER = 3

signal dispense(widget_position: Vector2, widget_type: int)

#region constructors

static func create(init_position: Vector2, widget_type: int) -> Dispenser:
	var new_dispenser: Dispenser = dispenser_packed.instantiate()
	new_dispenser.set_parameters(init_position, widget_type)
	return new_dispenser
	
	
static func create_from_save(save_dict: Dictionary) -> Dispenser:
	var new_dispenser: Dispenser = dispenser_packed.instantiate()
	new_dispenser.load_save_dict(save_dict)
	return new_dispenser


func set_parameters(init_position: Vector2, widget_type: int):
	set_machine_parameters(init_position, LAYER)
	type = widget_type
	var tex
	if type == 1:
		tex = load("res://Factory/Machine/Dispenser/dispenser_widget.png")
	elif type == 2:
		tex = load("res://Factory/Machine/Dispenser/dispenser_verywidget.png")
	
	$Sprite2D.texture = tex
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	
	if type == -1:
		type = 1
		var tex = load("res://Factory/Widget/widget.png")
		$Sprite2D.texture = tex
		
	
	pass # Replace with function body.


#endregion

func run_to(cycle: float):
	var cycle_fraction = fmod(cycle, 1)
	
	# This runs if it's the *last* update before the end
	# of the cycle
	if cycle - last_cycle >= (1-cycle_fraction):
		if(nearby_widgets.size() == 0 && \
		   round(cycle) - last_spawn_cycle >= cycle_spacing):
			do_dispense()
	
		
		
	last_cycle = cycle
		
	
	pass
	
func do_dispense():
	dispense.emit(position, type)
	last_spawn_cycle = round(last_cycle)
	
func get_type():
	return type


func get_delay():
	return cycle_spacing
	
func reset():
	super.reset()
	last_spawn_cycle = 0
	
#region saveAndLoad

func get_save_dict() -> Dictionary:
	var save_dict: Dictionary = {}
	save_dict["type"] = "dispenser"
	save_dict["pos"] = var_to_str(position)
	save_dict["dispenser_type"] = type
	save_dict["delay"] = cycle_spacing
	return save_dict
	
func load_save_dict(save_dict: Dictionary) -> void:
	set_parameters(str_to_var(save_dict["pos"]), save_dict["dispenser_type"])
	cycle_spacing = save_dict["delay"]

#endregion
	

func _on_delay_UI_change(new_spacing: int):
	cycle_spacing = new_spacing
