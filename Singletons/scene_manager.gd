extends Node

#var current_scene: Node



func switch_scene(scene_identifier: int) -> void:
	#get_tree().change_scene_to_file(Consts.SCENE_FILES[scene_identifier])
	var current = get_tree().current_scene
	get_tree().root.remove_child(current)
	current.queue_free()
	
	
	var new = load(Consts.SCENE_FILES[scene_identifier]).instantiate()
	get_tree().root.add_child(new)
	get_tree().current_scene = new
	
	
		
