extends Button
class_name InventoryButton

var assembly: Assembly
var quantity: int

static func create_from_item(item: InventoryItem) -> InventoryButton:
	var new_button: InventoryButton = InventoryButton.new()
	new_button.assembly = item.assembly
	new_button.quantity = item.quantity
	new_button.icon = item.assembly.get_thumbnail(100,100)
	return new_button
	

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0,100)
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
