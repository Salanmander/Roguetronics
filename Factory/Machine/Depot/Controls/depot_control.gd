extends Control
class_name DepotControl


func connect_to(depot: Depot) -> void:
	
	var widgets_grid: WidgetsGrid = $TabContainer/Accept/Product/GridLayer/Widgets
	
	# Disconnect all signals
	var conns: Array = widgets_grid.assembly_changed.get_connections()
	for conn in conns:
		conn.signal.disconnect(conn.callable)
		
	# TODO: set current grid showing to the plan from the connected
	# depot. Maybe reset controls, too?
	
	widgets_grid.assembly_changed.connect(depot._on_target_assembly_changed)
