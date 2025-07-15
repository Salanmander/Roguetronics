extends Node



func switch_scene(scene_identifier: int) -> void:
	get_tree().change_scene_to_file(Consts.SCENE_FILES[scene_identifier])
	
		
