extends Resource
class_name InventoryItem

var assembly: Assembly
var quantity: int

static func duplicate_item(item: InventoryItem) -> InventoryItem:
	var new_item = InventoryItem.new()
	new_item.assembly = item.assembly.clone()
	new_item.quantity = item.quantity
	return new_item
