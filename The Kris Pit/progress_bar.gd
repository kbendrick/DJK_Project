extends ProgressBar

var maximum_sanity: int = 5 
var current_sanity: int = 5 

@onready var label: Label = $Label

func _ready() -> void:
	update_gui()

func set_current_sanity (sanity) -> void:
	current_sanity = sanity
	update_gui()

func set_max_sanity (sanity) -> void:
	current_sanity = sanity
	update_gui()

func update_gui () -> void:
	self.max_value = maximum_sanity
	self.value = current_sanity
	label.text = str(current_sanity) + "/" + str(maximum_sanity)
