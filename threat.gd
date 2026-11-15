extends Node
class_name Threat

var threat_name: String
var effect_desc: String
var max_timer: int
var current_timer: int
var effect_func: Callable
var max_health: int
var current_health: int

func _init(i_threat_name: String = "",
i_effect_desc: String = "",
i_timer: int = 1000,
i_effect_func: Callable = func empty_func()->void: pass,
i_health: int = 0
) -> void:
	
	threat_name = i_threat_name
	effect_desc = i_effect_desc
	max_timer = i_timer
	current_timer = i_timer
	effect_func = i_effect_func
	max_health = i_health
	current_health = i_health
