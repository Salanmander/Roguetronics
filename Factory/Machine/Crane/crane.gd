extends Machine 
class_name Crane



static var crane_packed: PackedScene = load("res://Factory/Machine/Crane/crane.tscn")

const LAYER: int = -1

var grabber_open: bool

var last_pos: Vector2
var target_pos: Vector2

var initial_track_index: int

signal move_triggered(offset: int)
signal reset_triggered(start_index: int)
signal crashed()

var program: Array[int]
var held_widgets: Array[Widget]

# This changes state before the crane actually gets to the new layer
var raising: bool
var lowering: bool


#region constructors

static func create(init_position: Vector2) -> Crane:
	var new_crane = crane_packed.instantiate()
	new_crane.set_parameters(init_position)
	return new_crane

func set_parameters(init_position: Vector2):
	set_machine_parameters(init_position, LAYER)
	monitorable = true

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	open()
	program = []
	held_widgets = []
	raising = false
	lowering = false
	
#endregion

func run_to(cycle: float):
	
	# Crash if any widget is out-of-place relative to this crane.
	#for widget:Widget in held_widgets:
		#var widget_pos = widget.get_global_transform()
		#if not get_global_transform().is_equal_approx(widget_pos):
			#crashed.emit()
	
	var cycle_fraction: float = fmod(cycle, 1)
	
	# When this is the first move of a cycle
	if cycle - last_cycle >= cycle_fraction:
		last_pos = position
		target_pos = position # Default is stay still
		
		if program.size() > 0:
			# Run the next command
			var command:int = program[int(cycle) % program.size()]
			run_command(command)
		pass
	
	position = last_pos.lerp(target_pos, cycle_fraction)
	for widget:Widget in held_widgets:
		widget.force_to(position)
		
		
	# This runs if it's the *last* update before the end
	# of the cycle
	if cycle - last_cycle >= (1-cycle_fraction):
		if raising:
			# Monitor layer 2
			collision_mask = 0b10
			$Label.visible = true
		elif lowering:
			# Monitor layer 1
			collision_mask = 0b01
			$Label.visible = false
		
		if raising or lowering:
			for widget: Widget in held_widgets:
				widget.layer_change_initiate(collision_mask)
		
		raising = false
		lowering = false
		
	last_cycle = cycle

func reset():
	super.reset()
	
	open()
	collision_mask = 0b01
	$Label.visible = false
	
	raising = false
	lowering = false
	
	reset_triggered.emit(initial_track_index)
	
	
	
	
#region UI communication

func get_program() -> Array[int]:
	return program.duplicate()

func set_program(new_program: Array[int]):
	program = new_program.duplicate()
	
func _on_program_UI_change(new_program: Array[int]):
	set_program(new_program)

#endregion

#region movement

func set_target(target: Vector2):
	target_pos = target
	
func set_initial_index(ind: int):
	initial_track_index = ind
	
func teleport_to(pos: Vector2):
	position = pos
	
	
# Puts position at the middle of a grid square if it's close enough
func snap_to_grid():
	
	var center_position = Util.floor_map_to_local( Util.floor_local_to_map(position))
	if abs(position.x - center_position.x) < Consts.GRID_SIZE/16:
		position.x = center_position.x
	
	if abs(position.y - center_position.y) < Consts.GRID_SIZE/16:
		position.y = center_position.y
	

#endregion


#region commands

func run_command(command: int):
	if command == Consts.FORWARD:
		move_triggered.emit(1)
	if command == Consts.BACKWARD:
		move_triggered.emit(-1)
	if command == Consts.GRAB:
		close()
	if command == Consts.RELEASE:
		open()
	if command == Consts.RAISE:
		raising = true
	if command == Consts.LOWER:
		lowering = true

func open():
	grabber_open = true
	$OpenGrabber.visible = true
	$ClosedGrabber.visible = false
	
	for widget: Widget in held_widgets:
		widget.deleted.disconnect(_on_widget_deleted)
	held_widgets = []


func close():
	grabber_open = false
	$OpenGrabber.visible = false
	$ClosedGrabber.visible = true
	
	if held_widgets.size() == 0 && nearby_widgets.size() > 0:
		held_widgets = nearby_widgets.duplicate()
		for widget: Widget in held_widgets:
			widget.deleted.connect(_on_widget_deleted)

func is_open():
	return grabber_open

#endregion

func _on_widget_deleted(widget: Widget):
	held_widgets.erase(widget)
	
	
func _on_area_entered(other: Area2D):
	super._on_area_entered(other)
	if other is Crane:
		crashed.emit()
