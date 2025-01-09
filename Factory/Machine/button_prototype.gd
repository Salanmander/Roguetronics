extends Resource
class_name ButtonPrototype


var callback: String = ""
var callback_inputs: Array = []
var icon: CompressedTexture2D = null
var text: String = ""

func _init(call: String = "", 
		   ico: CompressedTexture2D = null,
		   tex: String = ""):
	callback = call
	icon = ico
	text = tex

func set_callback(call: String):
	callback = call
	
func set_icon(ico: CompressedTexture2D):
	icon = ico

func set_text(tex: String):
	text = tex


# TODO: Add variable amount of inputs to callback
func get_button(connect_to: Node) -> Button:
	var ret: Button = Button.new()
	ret.size = Vector2i(100, 100)
	ret.button_down.connect(func(): connect_to.callv(callback, callback_inputs))
	if(icon):
		ret.icon = icon
	else:
		ret.text = text
	return ret







