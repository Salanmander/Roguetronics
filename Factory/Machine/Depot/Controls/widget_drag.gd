extends Button

@export var widget_type: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _get_drag_data(at_position: Vector2) -> Dictionary:
	var preview: TextureRect = TextureRect.new()
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size = size*0.8
	
	var container: Control = Control.new()
	container.add_child(preview)
	preview.position = -0.5*preview.size
	
	
	set_drag_preview(container)
	var drag_data: Dictionary = {
		"type": "widget",
		"widget_type": widget_type
	}
	return drag_data
