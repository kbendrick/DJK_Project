extends StaticBody2D

var companion: Node2D = null

func _ready():
	modulate = Color(Color.MEDIUM_PURPLE, 0.7)

func _process(_dela):
	if global.is_dragging and companion == null:
		visible = true
	else:
		visible = false
