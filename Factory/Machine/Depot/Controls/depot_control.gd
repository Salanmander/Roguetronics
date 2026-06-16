extends Control
class_name DepotControl

func _init() -> void:
	tooltip_text = "The layout will run until each depot has received its
					required number. This is the number of this product 
					that will be available for later layouts."

func connect_to(depot: Depot) -> void:
	
	var widgets_grid: WidgetsGrid = $TabContainer/Accept/Product/GridLayer/Widgets
	var count_box: SpinBox = $TabContainer/Accept/Required/Count
	
	
	# Disconnect all signals
	var conns: Array = widgets_grid.assembly_changed.get_connections()
	conns.append_array(count_box.value_changed.get_connections())
	for conn in conns:
		conn.signal.disconnect(conn.callable)
		
	widgets_grid.set_grid_from_assembly(depot.get_product())
	count_box.set_value_no_signal(depot.get_required_number())
	
	widgets_grid.assembly_changed.connect(depot._on_target_assembly_changed)
	count_box.value_changed.connect(depot._on_required_number_changed)
	
	$TabContainer/Accept/PartSelectors/Link.button_pressed = false
	$TabContainer/Accept/PartSelectors/Delete.button_pressed = false
