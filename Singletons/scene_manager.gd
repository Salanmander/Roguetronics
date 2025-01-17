extends Node


var _scenes : Dictionary = {
	Consts.MAIN_MENU: "res://Menu/main__menu.tscn",
	Consts.FACTORY: "res://Factory/factory.tscn",
	Consts.REWARD: "res://Rewards/reward_screen.tscn"
}


func add_scene(scene_identifier: int, scene_path: String) -> void:
	_scenes[scene_identifier] = scene_path
	
func switch_scene(scene_identifier: int) -> void:
	get_tree().change_scene_to_file(_scenes[scene_identifier])
		


