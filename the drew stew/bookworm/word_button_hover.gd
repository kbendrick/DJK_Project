extends Button

func _ready() -> void:
	self.mouse_entered.connect(on_mouse_enter)
	self.mouse_exited.connect(on_mouse_exit)
	
func on_mouse_enter()->void:
	$"../../..".chosen_spell_hover = str(self.name)
	print(self.name)
	
func on_mouse_exit()->void:
	$"../../..".chosen_spell_hover = ""
	$"../../..".hover_text = null
