extends Machine 
class_name Crane


const LAYER: int = -1

var grabber_open: bool

var last_pos: Vector2
var target_pos: Vector2

var initial_track_index: int

signal move_triggered(offset: int)
signal reset_triggered(start_index: int)
signal crashed()

var program: Array[int]

func set_parameters(init_position: Vector2):
	set_machine_parameters(init_position, LAYER)
	monitorable = true

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	open()
	program = []

func run_to(cycle: float):
	
	var cycle_fraction: float = fmod(cycle, 1)
	
	# When this is the first move of a cycle
	if cycle - last_cycle >= cycle_fraction:
		last_pos = position
		target_pos = position # Default is stay still
		
		# Run the next command
		var command:int = program[int(cycle) % program.size()]
		run_command(command)
		pass
	
	position = last_pos.lerp(target_pos, cycle_fraction)
	last_cycle = cycle

func reset():
	super.reset()
	reset_triggered.emit(initial_track_index)
	
func run_command(command: int):
	if command == Consts.FORWARD:
		move_triggered.emit(1)
	if command == Consts.BACKWARD:
		move_triggered.emit(-1)
	pass
	
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
	

#endregion


#region commands

func open():
	grabber_open = true
	$LeftGrabber.open()
	$RightGrabber.open()

func close():
	grabber_open = false
	$LeftGrabber.close()
	$RightGrabber.close()

func is_open():
	return grabber_open

#endregion
	
func _on_area_entered(other: Area2D):
	super._on_area_entered(other)
	if other is Crane:
		crashed.emit()