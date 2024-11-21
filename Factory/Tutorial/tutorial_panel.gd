extends Panel

var displays: Array[Label]

signal closed


func _ready():
	displays.append($GoalDisplay)
	displays.append($ConveyorDisplay)
	displays.append($CombinerDisplay)
	displays.append($DispenserDisplay)
	displays.append($CraneDisplay)
	displays.append($ControlsDisplay)

func hide_all_displays():
	for disp:Label in displays:
		disp.visible = false
		
func show_display(to_show: Label):
	hide_all_displays()
	to_show.visible = true



func _on_goal_button_button_down():
	show_display($GoalDisplay)


func _on_conveyor_button_button_down():
	show_display($ConveyorDisplay)


func _on_combiner_button_button_down():
	show_display($CombinerDisplay)


func _on_dispenser_button_button_down():
	show_display($DispenserDisplay)


func _on_crane_button_button_down():
	show_display($CraneDisplay)


func _on_controls_button_button_down():
	show_display($ControlsDisplay)


func _on_close_button_button_down():
	closed.emit()
