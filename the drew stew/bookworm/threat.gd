extends Node
class_name Threat

@export var threat_name: String
@export var effect_desc: String
@export var max_timer: int
@export var current_timer: int
@export var effect_func: Callable
@export var max_health: int
@export var current_health: int
@export var freeze_timer: int = 0


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
