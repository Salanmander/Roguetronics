extends Node2D
class_name Assembly

var widgets:Array[Widget]
var nudges:Array[Vector2]
var queued_combine_widget:Widget

var last_cycle:float


var widget_packed:PackedScene = load("res://Factory/Widget/widget.tscn")

signal deleted(this_assembly:Assembly)

func _init():
	widgets = []
	nudges = []
	last_cycle = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Puts position at the middle of a grid square.
# Is passing in the TileMap a good idea? I don't know!
func snap_to_grid(grid:TileMap):
	position = grid.map_to_local( grid.local_to_map(position))
	
	
func run_to(cycle:float):
	
	var dLeft:float = 0
	var dRight:float = 0
	var dDown:float = 0
	var dUp:float = 0
	for nudge in nudges:
		var x:float = nudge.x
		var y:float = nudge.y
		if x > 0 && x > dRight:
			dRight = x
		if x < 0 && x < dLeft:
			dLeft = x
		if y > 0 && y > dDown:
			dDown = y
		if y < 0 && y < dUp:
			dUp = y
			
	var dx = dRight + dLeft
	var dy = dDown + dUp
	
	position += Vector2(dx, dy)
	
	nudges = []
	
	var cycle_fraction = fmod(cycle, 1)
	if cycle - last_cycle >= cycle_fraction:
		var printStr:String = str(widgets.size(), ": locations: ")
		for widget:Widget in widgets:
			printStr = str(printStr, "(", widget.position.x, ", ", widget.position.y, ")")
		print(printStr)
	last_cycle = cycle
	pass


func add_widget(new_widget:Widget):
	add_child(new_widget)
	widgets.append(new_widget)
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.combined.connect(_on_widget_combined)
	pass
	
func add_widget_from_other(new_widget:Widget, _other:Assembly):
	var keep_global_transform:bool = true
	new_widget.reparent(self, keep_global_transform)
	widgets.append(new_widget)
	new_widget.nudged.connect(_on_widget_nudged)
	new_widget.combined.connect(_on_widget_combined)
	
func get_widgets() -> Array[Widget]:
	return widgets.duplicate()
	
func _on_widget_nudged(delta:Vector2):
	nudges.append(delta)
	pass

func _on_widget_combined(widget:Widget, combiner:Combiner):
	var group_name:String = str("combining_by_",combiner.idString)
	var combining_assemblies:Array[Node] = get_tree().get_nodes_in_group(group_name)
	if combining_assemblies.size() == 1 && combining_assemblies[0] is Assembly:
		var other_assembly:Assembly = combining_assemblies[0]
		if other_assembly == self:
			return
		other_assembly.combine_with(self, widget)
		
	else:
		add_to_group(group_name)
		queued_combine_widget = widget
		combiner.drop.connect(_on_combiner_drop)
		
	pass
	
func combine_with(other: Assembly, _connect_point: Widget):
	assert(queued_combine_widget != null, "Error: Combine was initiated without connection point being set")
	
	var to_add:Array[Widget] = other.get_widgets()
	for widget in to_add:
		add_widget_from_other(widget, other)
	
	other.delete()
		
	pass

func delete():
	deleted.emit(self)
	queue_free()
	
func _on_combiner_drop(combiner:Combiner):
	combiner.drop.disconnect(_on_combiner_drop)
	var group_name:String = str("combining_by_",combiner.idString)
	remove_from_group(group_name)
	queued_combine_widget = null
