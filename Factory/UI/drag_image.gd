extends TextureRect

var held_item:int

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	texture = null
	
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible:
		position = get_global_mouse_position() - size/2
		
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			visible = false
	pass
	

func hold(item_number: int):
	texture = Consts.COMMAND_IMAGES[item_number]
	held_item = item_number
	visible = true


func is_holding() -> bool:
	return visible

func get_held_item() -> int:
	return held_item
	
	
