extends Panel
class_name CommandSlot


@onready var active_indicator: TextureRect = $ActiveIndicator
@onready var image: TextureRect = $CommandImage

var command: int

# Called when the node enters the scene tree for the first time.
func _ready():
	set_command(Consts.NO_COMMAND)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Use for debugging focus
	#focus_entered.connect(_on_gets_focus)
	#focus_exited.connect(_on_loses_focus)
	
func set_command(new_command: int):
	command = new_command
	image.texture = Consts.COMMAND_IMAGES[command]

func get_command() -> int:
	return command
	
func display_active(active: bool):
	active_indicator.visible = active
	
func _on_mouse_entered():
	grab_focus.call_deferred()
	
func _on_mouse_exited():
	release_focus.call_deferred()
	
	
	
# Use for debugging focus
#func _on_gets_focus():
	#modulate = Color(1, 0, 0, 1)
	#
#func _on_loses_focus():
	#modulate = Color(1, 1, 1, 1)
	
	
	

