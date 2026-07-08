extends GridContainer

# sends direction in radians
signal direction_changed(new_dir: float)


# float comes in as 0.5 for 0.5pi etc., because setting pi in the editor
# doesn't work well
func _on_direction_pressed(dir: float) -> void:
	direction_changed.emit(dir*PI)
	pass
