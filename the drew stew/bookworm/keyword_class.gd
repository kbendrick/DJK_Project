extends Node
class_name Keyword

var tag: String
var tag_code: String

var modifier: int
var element: String
var ability: Variant
var on_click_function: Callable

var key_weight: int
var hoverable: bool
var clickable: bool

#Constructor for Keyword Class
func _init(i_tag: String = "", 
i_tag_code: String = "", 
i_key_weight: int = 1, 
i_hoverable: bool = false, 
i_clickable: bool = false,
i_on_click_function: Callable = func empty_func()->void: pass) -> void:
	
	tag = i_tag
	tag_code = i_tag_code
	key_weight = i_key_weight
	hoverable = i_hoverable
	clickable = i_clickable
	on_click_function = i_on_click_function

#Premade Keywords
var default_tags: Dictionary = {
	"flip": ["flip", "[pulse freq=0.2 color=purple ease=2]flip[/pulse]", 10, true, true, func spread()->void: get_parent().make_spread()],
	"madness": ["madness","[pulse freq=0.2 color=red ease=2]madness[/pulse]", 1, true, false, func empty_func()->void: pass],
	"ignorance": ["ignorance","[pulse freq=0.2 color=yellow ease=2]ignorance[/pulse]", 5, true, false, func empty_func()->void: pass],
	"wisdom": ["widsom","[pulse freq=0.2 color=green ease=2]wisdom[/pulse]", 5, true, false, func empty_func()->void: pass]
}

#Constructor for Premade Default Keywords
func set_default(default_tag: String)->void:
	if default_tags.has(default_tag):
		tag = default_tags[default_tag][0]
		tag_code = default_tags[default_tag][1]
		key_weight = default_tags[default_tag][2]
		hoverable = default_tags[default_tag][3]
		clickable = default_tags[default_tag][4]
		on_click_function = default_tags[default_tag][5]
	else:
		print("default tag " + default_tag + " does not exist")

func on_click()->void:
	if on_click_function.is_valid():
		on_click_function.call()
