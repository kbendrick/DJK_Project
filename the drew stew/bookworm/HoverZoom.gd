@tool
extends RichTextEffect
class_name RichTextHover

# Define the BBCode tag name
var bbcode := "hover"

func _ready() -> void:
	# Connect the hover signals
	meta_hover_started.connect(_on_meta_hover_started)
	meta_hover_ended.connect(_on_meta_hover_ended)

func _on_meta_hover_started(meta: Variant) -> void:
	print("Hovering over meta: ", meta)
	# Add your custom logic here (e.g., showing a tooltip or changing text color)

func _on_meta_hover_ended(meta: Variant) -> void:
	print("Stopped hovering over meta: ", meta)
	# Hide tooltip or reset effect

func _process_custom_fx(char_fx: CharFXTransform):
		
		var offset := Vector2(0, 20)
		char_fx.offset = offset
		
		return true
