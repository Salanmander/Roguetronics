extends Control
class_name ResultScreen

@onready var before_label = $Panel/BeforeLabel
@onready var cost_label = $Panel/CostLabel
@onready var reward_label = $Panel/RewardLabel
@onready var after_label = $Panel/AfterLabel

signal result_accepted()
signal result_rejected()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func set_before(value: int) -> void:
	var prefix: String = "Money before run: $"
	before_label.text = prefix + str(value)
	
func set_cost(value: int) -> void:
	var prefix: String = "Cost of run: $"
	cost_label.text = prefix + str(value)
	
func set_reward(value: int) -> void:
	var prefix: String = "Reward: $"
	reward_label.text = prefix + str(value)
	
func set_after(value: int) -> void:
	var prefix: String = "Money after run: $"
	after_label.text = prefix + str(value)



func _on_accept_button_pressed() -> void:
	result_accepted.emit()


func _on_try_again_button_pressed() -> void:
	result_rejected.emit()
