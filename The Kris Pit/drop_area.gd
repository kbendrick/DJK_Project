extends StaticBody2D


const NORMAL_COLOR := Color(Color.MEDIUM_PURPLE, 0.7)
const HIGHLIGHT_COLOR := Color(Color.REBECCA_PURPLE, 1.0)

var companion: Node2D = null


func _ready() -> void:
	set_highlighted(false)


func _process(_delta: float) -> void:
	visible = global.is_dragging and companion == null


func set_highlighted(highlighted: bool) -> void:
	modulate = HIGHLIGHT_COLOR if highlighted else NORMAL_COLOR
