extends Control

@export var word_generator: PackedScene

var test_keywords: Array[String] = [ 
	"flip",
	"madness",
	"ignorance",
	"wisdom",
]

func _ready() -> void:
	
	#An array of default keywords
	var available_keywords: Array[Keyword]
	
	#Creates a Keyword class for each tag in test_keywords
	for keyword in test_keywords:
		var new_keyword = Keyword.new()
		new_keyword.set_default(keyword)
		available_keywords.append(new_keyword)
	
	#Creates a words scene and passes in array of Keywords
	var new_word_generator = word_generator.instantiate()
	add_child(new_word_generator)
	new_word_generator.setup(available_keywords)
