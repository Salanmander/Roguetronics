extends Control
class_name RewardScreen


func _ready():
	
	
	# Create buttons for available upgrades
	var upgradeContainer: GridContainer = $SelectionPanel

	for available: Upgrade in GameState.get_upgrades_available():
		
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
	
	
func _unhandled_input(event: InputEvent):
	var exact_match: bool = true
	if event.is_action_pressed("save", exact_match):
		GameState.save_to_disk.call_deferred()
	if event.is_action_pressed("load", exact_match):
		GameState.load_from_disk.call_deferred()
		
#region saveAndLoad

# No information needs to be saved for this scene yet, but these must
# be implemented for all scene top-level nodes
func get_save_dict() -> Dictionary:
	return {}
	
func load_from_save_dict(save_dict: Dictionary) -> void:
	pass

#endregion
	
	
func _on_new_machine_upgrade_pressed(machine_upgrade: NewMachine):
	GameState.add_machine(machine_upgrade)
	SceneManager.switch_scene(Consts.FACTORY)
	
func _on_machine_improvement_upgrade_pressed(upgrade: MachineImprovement):
	GameState.improve_machine(upgrade)
	SceneManager.switch_scene(Consts.FACTORY)
