extends Resource
class_name ButtonPrototype


var callback: String = ""
var callback_inputs: Array = []
var icon: CompressedTexture2D = null
var text: String = ""

func _init():
	callback = ""
	callback_inputs = []
	icon = null
	text = ""

func set_callback(new_call: String, inputs: Array = []):
	callback = new_call
	callback_inputs = inputs
	
func set_icon(ico: CompressedTexture2D):
	icon = ico

func set_text(tex: String):
	text = tex


# Returns a button that is connected to the given callback of the input object
func get_button(connect_to: Object) -> Button:
	var ret: Button = Button.new()
	ret.size = Vector2i(100, 100)
	ret.button_down.connect(func(): connect_to.callv(callback, callback_inputs))
	if(icon):
		ret.icon = icon
		ret.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ret.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		ret.text = text
	return ret
	
# Function to return the widget type of a dispenser button. Should only
# be called on buttons for dispensers
func get_dispenser_type() -> int:
	assert(callback == "_on_place_dispenser_pressed", "dispenser type requested for non-dispenser")
	return callback_inputs[0]
	
