extends Node
class_name Keyword

@export var tag: String
@export var tag_code: String
@export var bbcode_tag: String

@export var damage_modifier: int = 0
@export var heal_modifier: int = 0
@export var modifier_value: int = 0
@export var damage: int = 0
@export var heal: int = 0
@export var ability: Callable
@export var spell_word: bool

@export var interact_function: Callable
@export var modify_function:Callable

@export var key_weight: int
@export var hoverable: bool
@export var clickable: bool
@export var disabled: bool = false

#Constructor for Keyword Class
func _init(i_tag: String = "", 
i_tag_code: String = "", 
i_key_weight: int = 1, 
i_hoverable: bool = false, 
i_clickable: bool = false,
i_interact_function: Callable = func empty_func()->void: pass,
i_modify_function: Callable = func empty_func(_i:int)->void: pass) -> void:
	
	tag = i_tag
	tag_code = i_tag_code
	key_weight = i_key_weight
	hoverable = i_hoverable
	clickable = i_clickable
	interact_function = i_interact_function
	modify_function = i_modify_function
	
#Premade Keywords
var default_tags: Dictionary = {
	"flip": ["flip", "[pulse freq=0.2 color=purple ease=2]flip[/pulse]", 10, true, true, func spread()->void: get_parent().make_spread()],
	"madness": ["madness","[pulse freq=0.2 color=red ease=2]madness[/pulse]", 0, true, false, func empty_func()->void: pass],
	"ignorance": ["ignorance","[pulse freq=0.2 color=yellow ease=2]ignorance[/pulse]", 0, true, false, func empty_func()->void: pass],
	"wisdom": ["widsom","[pulse freq=0.2 color=green ease=2]wisdom[/pulse]", 0, true, false, func empty_func()->void: pass]
}

#Constructor for Premade Default Keywords
func set_default(default_tag: String)->void:
	if default_tags.has(default_tag):
		tag = default_tags[default_tag][0]
		tag_code = default_tags[default_tag][1]
		key_weight = default_tags[default_tag][2]
		hoverable = default_tags[default_tag][3]
		clickable = default_tags[default_tag][4]
		interact_function = default_tags[default_tag][5]
		ability = func ability()->String:
			return "Flip the page"
	else:
		print("default tag " + default_tag + " does not exist")

func interact()->void:
	if interact_function.is_valid():
		interact_function.call()

func modify(lane: int = 0)->void:
	if modify_function.is_valid():
		modify_function.call(lane)

func get_ability()->String:
	if ability.is_valid():
		return ability.call()
	return ""
