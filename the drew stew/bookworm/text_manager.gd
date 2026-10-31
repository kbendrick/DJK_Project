extends Control

@export var word_generator: PackedScene

var available_keywords: Array[Array] = [ 
	["flip", 10],
	["madness", 1],
	["ignorance", 5],
	["wisdom", 5],
]

func _ready() -> void:
	var new_word_generator = word_generator.instantiate()
	add_child(new_word_generator)
	new_word_generator.setup(available_keywords)
