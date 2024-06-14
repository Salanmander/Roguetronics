extends Node


func floor_map_to_local(map: Vector2i) -> Vector2:
	var half_square = Vector2(0.5, 0.5) * Consts.GRID_SIZE
	
	return map * Consts.GRID_SIZE + half_square


func floor_local_to_map(local: Vector2) -> Vector2i:

	return Vector2i((local/Consts.GRID_SIZE).floor())
