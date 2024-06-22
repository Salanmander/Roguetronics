extends Control
class_name DispenserControl

@onready var delay_box:SpinBox = $SpawnDelay

# Called when the node enters the scene tree for the first time.
func _ready():
	delay_box.min_value = 0
	delay_box.max_value = 100
	pass 
	
func connect_to(dispenser: Dispenser):
	# Disconnect all signals
	var conns: Array = delay_box.value_changed.get_connections()
	for conn in conns:
		conn.signal.disconnect(conn.callable)
	
	# Set values based on dispenser
	delay_box.set_value(dispenser.get_delay())
	
	delay_box.value_changed.connect(dispenser._on_delay_UI_change)
	




