extends Area2D

@onready var state_label: Label = $StateLabel

func set_state(state: String):
	state_label.text = state
