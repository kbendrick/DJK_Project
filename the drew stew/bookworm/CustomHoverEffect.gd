extends RichTextEffect
class_name RichTextHover

var bbcode := "hover"
func _process_custom_fx(char_fx):
	
	var speed = char_fx.env.get("speed", 5.0)
	var transform = Vector2(1.5, 1.5)
	char_fx.transform = transform
