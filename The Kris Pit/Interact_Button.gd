extends Button

func _on_pressed() -> void:
	global.is_locked = true

func _process(_delta: float) -> void:
	if global.is_locked:
		visible = false
