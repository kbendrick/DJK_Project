extends Control

@export var word_generator: PackedScene

var rng = RandomNumberGenerator.new()
var turn_count: int = 1
var hover_text: Keyword
var lock: bool = false
var main_threat_max_health: int = 70
var main_threat_current_health: int = 70

var test_keywords: Array[String] = [ 
	"flip",
	"madness",
	"ignorance",
	"wisdom",
]

var threat_pool: Array[Threat]

var chosen_spell_words: Array[Keyword] = [Keyword.new(),Keyword.new(),Keyword.new()]
var threat_lanes: Array[Threat] = [Threat.new(), Threat.new(), Threat.new()]

var cast_lane_helper: int

func _ready() -> void:
	
	threat_pool.append(Threat.new(
		"Fist",
		"Fist deals 5 damage",
		5,
		func fist(): Player.current_health -= 5,
		20
	))
	
	threat_pool.append(Threat.new(
		"Slap",
		"Slap deals 3 damage",
		3,
		func slap(): Player.current_health -= 3,
		10
	))
	
	threat_pool.append(Threat.new(
		"Poke",
		"Poke deals 1 damage",
		1,
		func poke(): Player.current_health -= 1,
		5
	))
	
	add_threat(threat_pool[rng.randi_range(0,2)].duplicate())
	add_threat(threat_pool[rng.randi_range(0,2)].duplicate())
	
	#An array of default keywords
	var available_keywords: Array[Keyword]
	
	#Creates a Keyword class for each tag in test_keywords
	for keyword in test_keywords:
		var new_keyword = Keyword.new()
		new_keyword.set_default(keyword)
		available_keywords.append(new_keyword)
	
	available_keywords.append(Keyword.new(
		"explosion",
		"[pulse freq=0.2 color=orange ease=2]explosive[/pulse]",
		5, true, false
	))
	available_keywords[4].spell_word = true
	available_keywords[4].modifier = 3
	
	available_keywords[4].on_click_function = func aoe_damage(
		damage:int = chosen_spell_words[cast_lane_helper].modifier): 
			for threats in threat_lanes:
				threats.current_health -= damage
	
	available_keywords[4].ability = "Deal" + str(chosen_spell_words[cast_lane_helper].modifier) + "damage to each threat"
	
	available_keywords.append(Keyword.new(
		"sparkles",
		"[pulse freq=0.2 color=hotpink ease=2]sparkles[/pulse]",
		5, true, false
	))
	available_keywords[5].spell_word = true
	available_keywords[5].modifier = 2
	
	available_keywords[5].on_click_function = func multihit_damage(
		damage:int = chosen_spell_words[cast_lane_helper].modifier): 
			for i in range(3):
				threat_lanes[cast_lane_helper].current_health -= damage
	
	available_keywords[5].ability = "Deal" + str(chosen_spell_words[cast_lane_helper].modifier) + "damage 3 times the threat in this lane"
	
	available_keywords.append(Keyword.new(
		"freeze",
		"[pulse freq=0.2 color=deepskyblue ease=2]freeze[/pulse]",
		5, true, false
	))
	available_keywords[6].spell_word = true
	
	available_keywords[6].on_click_function = func freeze(): 
		threat_lanes[cast_lane_helper].freeze_timer += 2
	
	available_keywords[6].ability = "Freeze the threat in this lane for 2 turns"
	
	#Creates a words scene and passes in array of Keywords
	var new_word_generator = word_generator.instantiate()
	$VBoxContainer.add_child(new_word_generator)
	new_word_generator.setup(available_keywords)
	
	$VBoxContainer/SpellHBox/Word1.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word1))
	$VBoxContainer/SpellHBox/Word2.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word2))
	$VBoxContainer/SpellHBox/Word3.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word3))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("spacebar") and not lock:
		lock = true
		end_turn()
	if Input.is_action_just_pressed("1"):
		if hover_text != null:
			if hover_text.spell_word:
				if not hover_text.disabled:
					chosen_spell_words[0] = hover_text
					self.get_node("VBoxContainer/Words").meta_disabled(hover_text.bbcode_tag)
	if Input.is_action_just_pressed("2"):
		if hover_text != null:
			if hover_text.spell_word:
				if not hover_text.disabled:
					chosen_spell_words[1] = hover_text
					self.get_node("VBoxContainer/Words").meta_disabled(hover_text.bbcode_tag)
	if Input.is_action_just_pressed("3"):
		if hover_text != null:
			if hover_text.spell_word:
				if not hover_text.disabled:
					chosen_spell_words[2] = hover_text
					self.get_node("VBoxContainer/Words").meta_disabled(hover_text.bbcode_tag)
				
			
	
	$VBoxContainer/HBoxContainer/PlayerHealth.max_value = Player.max_health
	$VBoxContainer/HBoxContainer/PlayerHealth.value = Player.current_health
	$VBoxContainer/HBoxContainer/TurnCount.text = "Turn " + str(turn_count)
	$VBoxContainer/HBoxContainer/PlayerHealth/HealthLabel.text = str(Player.current_health) + "/" + str(Player.max_health)
	$VBoxContainer/ProgressBar/HealthLabel.text = str(main_threat_current_health) + "/" + str(main_threat_max_health)
	
	if threat_lanes[0].threat_name != "":
		$VBoxContainer/HealthHBox/Threat_Bar1/Name_health.visible = true
		$VBoxContainer/LaneHBox/Effect1/Timer.visible = true
	else:
		$VBoxContainer/HealthHBox/Threat_Bar1/Name_health.visible = false
		$VBoxContainer/LaneHBox/Effect1/Timer.visible = false
	$VBoxContainer/HealthHBox/Threat_Bar1/Name_health.text = threat_lanes[0].threat_name + " " + str(str(threat_lanes[0].current_health) + " / " + str(threat_lanes[0].max_health))
	$VBoxContainer/LaneHBox/Effect1/Effect.text = threat_lanes[0].effect_desc
	$VBoxContainer/LaneHBox/Effect1/Timer.text = str(threat_lanes[0].current_timer)
	if threat_lanes[0].freeze_timer > 0:
		$VBoxContainer/LaneHBox/Effect1/Timer.add_theme_color_override("font_color", Color.DEEP_SKY_BLUE)
	else:
		$VBoxContainer/LaneHBox/Effect1/Timer.add_theme_color_override("font_color", Color.DARK_RED)
	$VBoxContainer/HealthHBox/Threat_Bar1.max_value = threat_lanes[0].max_health
	$VBoxContainer/HealthHBox/Threat_Bar1.value = threat_lanes[0].current_health

	if threat_lanes[1].threat_name != "":
		$VBoxContainer/HealthHBox/Threat_Bar2/Name_health.visible = true
		$VBoxContainer/LaneHBox/Effect2/Timer.visible = true
	else:
		$VBoxContainer/HealthHBox/Threat_Bar2/Name_health.visible = false
		$VBoxContainer/LaneHBox/Effect2/Timer.visible = false
	$VBoxContainer/HealthHBox/Threat_Bar2/Name_health.text = threat_lanes[1].threat_name + " " + str(str(threat_lanes[1].current_health) + " / " + str(threat_lanes[1].max_health))
	$VBoxContainer/LaneHBox/Effect2/Effect.text = threat_lanes[1].effect_desc
	$VBoxContainer/LaneHBox/Effect2/Timer.text = str(threat_lanes[1].current_timer)
	if threat_lanes[1].freeze_timer > 0:
		$VBoxContainer/LaneHBox/Effect2/Timer.add_theme_color_override("font_color", Color.DEEP_SKY_BLUE)
	else:
		$VBoxContainer/LaneHBox/Effect2/Timer.add_theme_color_override("font_color", Color.DARK_RED)
	$VBoxContainer/HealthHBox/Threat_Bar2.max_value = threat_lanes[1].max_health
	$VBoxContainer/HealthHBox/Threat_Bar2.value = threat_lanes[1].current_health

	if threat_lanes[2].threat_name != "":
		$VBoxContainer/HealthHBox/Threat_Bar3/Name_health.visible = true
		$VBoxContainer/LaneHBox/Effect3/Timer.visible = true
	else:
		$VBoxContainer/HealthHBox/Threat_Bar3/Name_health.visible = false
		$VBoxContainer/LaneHBox/Effect3/Timer.visible = false
	$VBoxContainer/HealthHBox/Threat_Bar3/Name_health.text = threat_lanes[2].threat_name + " " + str(str(threat_lanes[2].current_health) + " / " + str(threat_lanes[2].max_health))
	$VBoxContainer/LaneHBox/Effect3/Effect.text = threat_lanes[2].effect_desc
	$VBoxContainer/LaneHBox/Effect3/Timer.text = str(threat_lanes[2].current_timer)
	if threat_lanes[2].freeze_timer > 0:
		$VBoxContainer/LaneHBox/Effect3/Timer.add_theme_color_override("font_color", Color.DEEP_SKY_BLUE)
	else:
		$VBoxContainer/LaneHBox/Effect3/Timer.add_theme_color_override("font_color", Color.DARK_RED)
	
	$VBoxContainer/HealthHBox/Threat_Bar3.max_value = threat_lanes[2].max_health
	$VBoxContainer/HealthHBox/Threat_Bar3.value = threat_lanes[2].current_health

	$VBoxContainer/SpellHBox/Word1.text = chosen_spell_words[0].tag
	$VBoxContainer/SpellHBox/Word2.text = chosen_spell_words[1].tag
	$VBoxContainer/SpellHBox/Word3.text = chosen_spell_words[2].tag

func choose_spell_word(keyword: Keyword) -> void:
	chosen_spell_words[keyword.spell_word_type] = keyword
	
func add_threat(threat: Threat) -> void:
	var available_lanes: Array[int]
	
	for i in (threat_lanes.size()):
		if threat_lanes[i].threat_name == "":
			available_lanes.append(i)
	
	print(available_lanes)
	
	if available_lanes.is_empty():
		return
	
	while true:
		var number = rng.randi_range(0,2)
		if available_lanes.has(number):
			threat_lanes[number] = threat
			break

func spell_word_pressed(button: Button)-> void:
	
	if button == $VBoxContainer/SpellHBox/Word1:
		chosen_spell_words[0] = Keyword.new()
	if button == $VBoxContainer/SpellHBox/Word2:
		chosen_spell_words[1] = Keyword.new()
	if button == $VBoxContainer/SpellHBox/Word3:
		chosen_spell_words[2] = Keyword.new()
		
func cast_spells()-> void:
	for keyword in chosen_spell_words.size():
		cast_lane_helper = keyword
		if chosen_spell_words[keyword].tag != "":
			chosen_spell_words[keyword].on_click_function.call()
			chosen_spell_words[keyword] = Keyword.new()
		var process_timer = get_tree().create_timer(0.75)
		await process_timer.timeout
		

func check_lanes()-> void:
	turn_count += 1
	print("turn count: " + str(turn_count))
	
	var mod_count = (turn_count % 3)+1
	
	if mod_count == 3:
		add_threat(threat_pool[rng.randi_range(0,2)].duplicate())
		add_threat(threat_pool[rng.randi_range(0,2)].duplicate())
	
	var timer = get_tree().create_timer(0.55)
	await timer.timeout
		
	
	return

func damage_lane(lane_number: int, damage: int)->void:
	if threat_lanes[lane_number].threat_name == "":
		main_threat_current_health -= damage
	else:
		threat_lanes[lane_number].current_health -= damage

func end_turn()-> void:
	cast_spells()
		
	for index in (threat_lanes.size()):
		
		if threat_lanes[index].current_health <= 0:
			threat_lanes[index] = Threat.new()
			
			var threat_death_timer = get_tree().create_timer(0.75)
			await threat_death_timer.timeout
			
			continue
		
		if threat_lanes[index].freeze_timer > 0:
			threat_lanes[index].freeze_timer -= 1
			continue
		
		if threat_lanes[index].current_timer > 0:
			threat_lanes[index].current_timer -= 1
			if threat_lanes[index].current_timer > 0:
				var threat_continue_timer = get_tree().create_timer(0.75)
				await threat_continue_timer.timeout
				continue
		
		threat_lanes[index].effect_func.call()
		health_check()
		
		var timer = get_tree().create_timer(0.5)
		await timer.timeout
		
		threat_lanes[index] = Threat.new()
		
		timer = get_tree().create_timer(0.55)
		await timer.timeout
		
	check_lanes()
	lock = false
	return

func game_over()-> void:
	return

func health_check()-> void:
	if Player.current_health <= 0:
		game_over()
	else:
		var health_percentage = float(Player.current_health) / float(Player.max_health)
		var healthbar_fill = $VBoxContainer/HBoxContainer/PlayerHealth.get_theme_stylebox("fill")
		if health_percentage <= 0.25:
			healthbar_fill.bg_color= Color("640000")
		elif health_percentage <= 0.5:
			healthbar_fill.bg_color = Color("646400")
		else:
			healthbar_fill.bg_color = Color("006400")
