extends Control

@export var word_generator: PackedScene

var test_keywords: Array[String] = [ 
	"flip",
	"madness",
	"ignorance",
	"wisdom",
]

var chosen_spell_words: Array[Keyword] = [Keyword.new(),Keyword.new(),Keyword.new()]

func _ready() -> void:
	
	#An array of default keywords
	var available_keywords: Array[Keyword]
	
	#Creates a Keyword class for each tag in test_keywords
	for keyword in test_keywords:
		var new_keyword = Keyword.new()
		new_keyword.set_default(keyword)
		available_keywords.append(new_keyword)
	
	available_keywords.append(Keyword.new(
		"explosive",
		"[pulse freq=0.2 color=orange ease=2]explosive[/pulse]",
		5, true, true
	))
	available_keywords[4].spell_word_type = 0
	available_keywords[4].on_click_function = func store_word()->void: self.choose_spell_word(available_keywords[4])
	
	available_keywords.append(Keyword.new(
		"sad",
		"[pulse freq=0.2 color=blue ease=2]sad[/pulse]",
		5, true, true
	))
	available_keywords[5].spell_word_type = 1
	available_keywords[5].on_click_function = func store_word()->void: self.choose_spell_word(available_keywords[5])
	
	available_keywords.append(Keyword.new(
		"sparkles",
		"[pulse freq=0.2 color=hotpink ease=2]sparkles[/pulse]",
		5, true, true
	))
	available_keywords[6].spell_word_type = 2
	available_keywords[6].on_click_function = func store_word()->void: self.choose_spell_word(available_keywords[6])
	
	#Creates a words scene and passes in array of Keywords
	var new_word_generator = word_generator.instantiate()
	$VBoxContainer.add_child(new_word_generator)
	new_word_generator.setup(available_keywords)
	
	$VBoxContainer/SpellHBox/Word1.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word1))
	$VBoxContainer/SpellHBox/Word2.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word2))
	$VBoxContainer/SpellHBox/Word3.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word3))

func _process(_delta: float) -> void:
	
		$VBoxContainer/SpellHBox/Word1.text = chosen_spell_words[0].tag
		$VBoxContainer/SpellHBox/Word2.text = chosen_spell_words[1].tag
		$VBoxContainer/SpellHBox/Word3.text = chosen_spell_words[2].tag

func choose_spell_word(keyword: Keyword) -> void:
	chosen_spell_words[keyword.spell_word_type] = keyword

func spell_word_pressed(button: Button)-> void:
	
	if button == $VBoxContainer/SpellHBox/Word1:
		chosen_spell_words[0] = Keyword.new()
	if button == $VBoxContainer/SpellHBox/Word2:
		chosen_spell_words[1] = Keyword.new()
	if button == $VBoxContainer/SpellHBox/Word3:
		chosen_spell_words[2] = Keyword.new()
