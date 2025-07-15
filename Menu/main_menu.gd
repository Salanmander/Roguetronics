extends Control
class_name MainMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# TEMP
	GameState.load_from_disk.call_deferred()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_new_game_pressed() -> void:
	SceneManager.switch_scene(Consts.FACTORY)
	pass # Replace with function body.


func _on_continue_pressed() -> void:
	pass # Replace with function body.
