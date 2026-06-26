extends Control
class_name DepotControl

func _ready() -> void:
	var requirement_box: HBoxContainer = $TabContainer/Accept/Required
	requirement_box.tooltip_text = "The layout will run until each depot has received its
					required number. This is the number of this product 
					that will be available for later layouts."

func connect_to(depot: Depot) -> void:
	
	var widgets_grid: WidgetsGrid = $TabContainer/Accept/Product/GridLayer/Widgets
	var count_box: SpinBox = $TabContainer/Accept/Required/Count
	var inventory_panel: GridContainer = $TabContainer/Dispense/InventoryButtons
	
	
	# Disconnect all signals
	var conns: Array = widgets_grid.assembly_changed.get_connections()
	conns.append_array(count_box.value_changed.get_connections())
	conns.append_array($TabContainer.tab_changed.get_connections())
	for conn in conns:
		conn.signal.disconnect(conn.callable)
	
	# Set current value of controls, and connect signals for changes
	widgets_grid.set_grid_from_assembly(depot.get_product())
	count_box.set_value_no_signal(depot.get_required_number())
	
	widgets_grid.assembly_changed.connect(depot._on_target_assembly_changed)
	count_box.value_changed.connect(depot._on_required_number_changed)
	
	# Connect buttons for items to dispense
	for button: Node in inventory_panel.get_children():
		if button is InventoryButton:
			# disconnect button signals
			conns = button.button_down.get_connections()
			for conn in conns:
				conn.signal.disconnect(conn.callable)
			
			button.button_down.connect(depot._on_target_assembly_changed.bind(button.assembly))
		pass
	
	# Set current accept/dispense control visibility
	if depot.mode == depot.ACCEPT:
		assert($TabContainer.get_tab_title(0) == "Accept", "Incorrect tab arrangement?")
		$TabContainer.current_tab = 0
	else:
		assert($TabContainer.get_tab_title(1) == "Dispense", "Incorrect tab arrangement?")
		$TabContainer.current_tab = 1
	
	# Connect signal for changing from accept to dispense
	$TabContainer.tab_changed.connect(depot._on_controls_tab_changed.bind($TabContainer))
	
	# Reset button states
	$TabContainer/Accept/PartSelectors/Link.button_pressed = false
	$TabContainer/Accept/PartSelectors/Delete.button_pressed = false


func set_inventory( inventory: Array[InventoryItem] ) -> void:
	# Remove all current buttons
	var buttons: Array[Node] = $TabContainer/Dispense/InventoryButtons.get_children()
	for button: Node in buttons:
		if button is Button:
			button.queue_free()
			$TabContainer/Dispense/InventoryButtons.remove_child(button)
	
	for item: InventoryItem in inventory:
		var button: Button = InventoryButton.create_from_item(item)
		$TabContainer/Dispense/InventoryButtons.add_child(button)
	pass
