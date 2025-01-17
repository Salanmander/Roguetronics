extends Control


func _ready():
	
	# Create buttons for available upgrades
	var upgradeContainer: GridContainer = $SelectionPanel

	for available: Upgrade in GameState.upgrades_available:
		
		var proto: ButtonPrototype = available.get_button_prototype()
		var button: Button = proto.get_button(self)
		
		var width: float = upgradeContainer.size.x / upgradeContainer.columns
		var height: float = upgradeContainer.size.y / 2
		button.custom_minimum_size = Vector2(width, height)
		button.expand_icon = true
		upgradeContainer.add_child(button)
	pass # Replace with function body.


func _process(delta):
	pass
	
	
func _on_new_machine_upgrade_pressed(machine_prototype_path: String):
	GameState.add_machine(machine_prototype_path)
	SceneManager.switch_scene(Consts.FACTORY)
