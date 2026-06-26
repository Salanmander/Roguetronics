extends Control

const NONE: int = 0
const LINK: int = 1
const DEL: int = 2

var click_mode: int = NONE


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: The way this is scaled will probably need to change
	# when supporting different resolutions. Probably make it
	# control the Grid size, rather than vice versa
	custom_minimum_size = $GridLayer/Grid.get_used_rect().size*Consts.GRID_SIZE*$GridLayer.scale



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		event = make_input_local(event)
		var pos: Vector2 = event.position
		# TODO: this input isn't working. Figure out why. Might be related to
		# grid on inactive tab still processing input?
		if(pos.x <= custom_minimum_size.x and pos.x >= 0):
			if(pos.y <= custom_minimum_size.y and pos.y >= 0):
				# Requires that x and y scale be the same
				pos *= 1/($GridLayer.scale.x)
				if( click_mode == DEL ):
					$GridLayer/Widgets.set_widget(pos, -1)
				if( click_mode == LINK ):
					$GridLayer/Widgets.create_link(pos)
	pass


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if( data is Dictionary and data.has("type") ):
		if( data["type"] == "widget" ):
			return true
			
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Requires that x and y scale be the same
	at_position *= 1/($GridLayer.scale.x)
	$GridLayer/Widgets.set_widget(at_position, data["widget_type"])
	pass


func _on_link_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		click_mode = LINK
	else:
		click_mode = NONE


func _on_delete_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		click_mode = DEL
	else:
		click_mode = NONE
