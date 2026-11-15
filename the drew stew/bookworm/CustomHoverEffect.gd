@tool
extends RichTextEffect
class_name RichTextHover

var scale = 1

# Define the BBCode tag name
@export var bbcode := "hover"

func _on_meta_hover_started(_meta: Variant) -> void:
	scale = 1.2
	print(bbcode)
	# Add your custom logic here (e.g., showing a tooltip or changing text color)

func _on_meta_hover_ended(_meta: Variant) -> void:
	scale = 1
	print(bbcode)
	# Hide tooltip or reset effect

func disabled() -> void:
	print(bbcode)
	bbcode = "disabled"
	scale = 1

func _process_custom_fx(char_fx: CharFXTransform):
		
		var scale_vector = Vector2(scale, scale)
		char_fx.transform = char_fx.transform.scaled_local(scale_vector)
		
		return true
