extends Machine
class_name Depot

static var LAYER: int = 0

static var depot_packed = load("res://Factory/Machine/Depot/depot.tscn")
static var accept_background = load("res://Factory/Machine/Depot/depot_accept.png")
static var dispense_up_background = load("res://Factory/Machine/Depot/depot_dispense_up.png")
static var dispense_right_background = load("res://Factory/Machine/Depot/depot_dispense_right.png")

signal completed()
signal dispense(assembly_possition: Vector2, assembly: Assembly)

const ACCEPT: int = 1
const DISPENSE: int = 2
var mode: int = ACCEPT

var limit_count: int = 0
var limit: bool = false
var num_dispensed: int = 0

var last_spawn_cycle: int = 0
var cycle_spacing: int = 4


#region constructors

static func create(pos: Vector2) -> Depot:
	var new_depot: Depot = depot_packed.instantiate()
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

#endregion

func run_to(cycle: float) -> void:
	if( mode == ACCEPT ):
		# This runs if it's the first update of the cycle
		var cycle_fraction = fmod(cycle, 1)
		if cycle - last_cycle >= cycle_fraction:
			var nearby_assemblies: Array[Assembly] = []
			for widget: Widget in nearby_widgets:
				if( not widget.parent_assembly in nearby_assemblies ):
					nearby_assemblies.append(widget.parent_assembly)
			$Goal.check_against(nearby_assemblies)
	else:
		$Belt.run_to(cycle)
		# This runs if it's the *last* update before the end
		# of the cycle
		var cycle_fraction = fmod(cycle, 1)
		if cycle - last_cycle >= (1-cycle_fraction):
			if(nearby_widgets.size() == 0 && \
			   round(cycle) - last_spawn_cycle >= cycle_spacing):
				do_dispense()
	last_cycle = cycle
	
func do_dispense() -> void:
	if(mode == DISPENSE and ((not limit) or num_dispensed < limit_count)):
		dispense.emit(position, $Goal.get_plan())
		last_spawn_cycle = round(last_cycle)
		num_dispensed += 1

func reset() -> void:
	super()
	num_dispensed = 0
	$Belt.reset()
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
	$Belt.set_collision_grid_size(grid_size)
	
	
	$DepotBackground.region_rect = Rect2(0, 0, right, bottom)

func switch_to_accept() -> void:
	$DepotBackground.texture = accept_background
	mode = ACCEPT
	pass
	
func switch_to_dispense() -> void:
	_on_dispense_direction_changed(0)
	mode = DISPENSE
	pass

#region communication with other nodes
# pos is local to the Depot
func contains_point(pos: Vector2) -> bool:
	return $DepotBackground.region_rect.has_point(pos - $DepotBackground.position)

func get_product() -> Assembly:
	return $Goal.get_plan()

func get_required_number() -> int:
	return $Goal.copies_needed
	
func awaiting_product() -> bool:
	return ( mode == ACCEPT and $Goal.copies_made < $Goal.copies_needed )

# Returns inventory item with positive quantity for produced, or negative
# quantity for consumed
func get_intended_production() -> InventoryItem:
	var produced: InventoryItem =  InventoryItem.new()
	produced.assembly = $Goal.get_plan()
	
	# If the assembly is empty, don't return anything at all
	if produced.assembly.get_widgets().size() == 0:
		return null
	
	if( mode == ACCEPT ):
		produced.quantity = $Goal.copies_needed
	else:
		if( limit ):
			# use negative quantity for dispensed products
			produced.quantity = -limit_count
		else:
			# a billion should be enough to consume everything...
			produced.quantity = -1000000000
			
	return produced
	

# Returns null if the depot is consuming inventory
func get_produced_inventory() -> InventoryItem:
	if( mode != ACCEPT ):
		return null
	var produced: InventoryItem =  InventoryItem.new()
	produced.assembly = $Goal.get_plan()
	
	# If the assembly is empty, don't return anything at all
	if produced.assembly.get_widgets().size() == 0:
		return null
	

	produced.quantity = $Goal.copies_made
	return produced
	
#endregion

func _on_target_assembly_changed(new_assembly: Assembly) -> void:
	$Goal.set_plan(new_assembly)
	update_background_size()

# 0 is facing straight up, and then rotates to the right. Passed in in radians
func _on_dispense_direction_changed(new_dir: float) -> void:
	if(is_equal_approx(new_dir, 0)):
		$DepotBackground.texture = dispense_up_background
		$DepotBackground.flip_v = false
	elif(is_equal_approx(new_dir, PI)):
		$DepotBackground.texture = dispense_up_background
		$DepotBackground.flip_v = true
	elif(is_equal_approx(new_dir, PI/2)):
		$DepotBackground.texture = dispense_right_background
		$DepotBackground.flip_h = false
	elif(is_equal_approx(new_dir, 3*PI/2)):
		$DepotBackground.texture = dispense_right_background
		$DepotBackground.flip_h = true
	$Belt.set_direction(new_dir)

func _on_dispense_limit_toggled(should_limit: bool) -> void:
	limit = should_limit

func _on_limit_count_changed(new_limit: int) -> void:
	limit_count = new_limit
	
	
func _on_required_number_changed(new_count: int) -> void:
	$Goal.copies_needed = new_count
	
func _on_controls_tab_changed(tab_idx: int, controls: TabContainer) -> void:
	var tab_name: String = controls.get_tab_title(tab_idx)
	if(tab_name == "Accept"):
		switch_to_accept()
	else:
		switch_to_dispense()
	
func _on_requirement_met() -> void:
	completed.emit()
	pass
