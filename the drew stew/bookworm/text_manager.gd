extends Control

@export var word_generator: PackedScene

var rng = RandomNumberGenerator.new()
var turn_count: int = 1
var hover_text: Keyword
var lock: bool = false
var main_threat_max_health: int = 70
var main_threat_current_health: int = 70

var hovered_ability: String

var casting_timer: float

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
var chosen_spell_hover: String

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
		"[pulse freq=0.8 color=orange ease=2]explosive[/pulse]",
		5, true, false
	))
	available_keywords[4].spell_word = true
	available_keywords[4].damage = 3
	
	available_keywords[4].interact_function = func aoe_damage(
		damage:int = chosen_spell_words[cast_lane_helper].damage, damage_modifier:int = chosen_spell_words[cast_lane_helper].damage_modifier): 
			for threats in threat_lanes:
				threats.current_health -= damage + damage_modifier
	
	available_keywords[4].ability = func ability()-> String: 
		return "Deal " + str(hover_text.damage + hover_text.damage_modifier) + " damage to each threat"
	
	available_keywords.append(Keyword.new(
		"sparkles",
		"[pulse freq=0.8 color=hotpink ease=2]sparkles[/pulse]",
		5, true, false
	))
	available_keywords[5].spell_word = true
	available_keywords[5].damage = 1
	
	available_keywords[5].interact_function = func multihit_damage(
		damage:int = chosen_spell_words[cast_lane_helper].damage, damage_modifier:int = chosen_spell_words[cast_lane_helper].damage_modifier): 
			for i in range(5):
				threat_lanes[cast_lane_helper].current_health -= damage + damage_modifier
				var cast_time = get_tree().create_timer(0.25)
				await cast_time.timeout
	
	available_keywords[5].ability = func ability()->String: 
		return "Deal " + str(hover_text.damage + hover_text.damage_modifier) + " damage 5 times to the threat in this lane"
	
	available_keywords.append(Keyword.new(
		"freeze",
		"[pulse freq=0.8 color=deepskyblue ease=2]freeze[/pulse]",
		5, true, false
	))
	available_keywords[6].spell_word = true
	
	available_keywords[6].interact_function = func freeze(): 
		threat_lanes[cast_lane_helper].freeze_timer += 2
	
	available_keywords[6].ability = func ability()->String: 
		return "Freeze the threat in this lane for 2 turns"
	
	available_keywords.append(Keyword.new(
		"heal",
		"[pulse freq=0.8 color=green ease=2]heal[/pulse]",
		5, true, false
	))
	
	available_keywords[7].spell_word = true
	
	available_keywords[7].heal = 2
	
	available_keywords[7].interact_function = func heal():
		Player.current_health += chosen_spell_words[cast_lane_helper].heal + chosen_spell_words[cast_lane_helper].heal_modifier
		
	available_keywords[7].ability = func ability()->String: 
		return "Heal " + str(hover_text.heal + hover_text.heal_modifier)
	
	available_keywords.append(Keyword.new(
		"enhance",
		"[pulse freq=0.8 color=yellow ease=2]enhance[/pulse]",
		5, true, false
	))
	
	available_keywords[8].spell_word = true
	
	available_keywords[8].modifier_value = 2
	
	available_keywords[8].modify_function = func enhance(lane:int = 0):
		if lane + 1 < 3:
			chosen_spell_words[lane+1].damage_modifier = chosen_spell_words[lane].modifier_value
		if lane - 1 > -1:
			chosen_spell_words[lane-1].damage_modifier = chosen_spell_words[lane].modifier_value
			
	available_keywords[8].ability = func ability()->String: 
		return "Adjacent spells deal +" + str(hover_text.modifier_value) + " damage"
	
	available_keywords.append(Keyword.new(
		"blast",
		"[pulse freq=0.8 color=red ease=2]blast[/pulse]",
		5, true, false
	))
	available_keywords[9].spell_word = true
	available_keywords[9].damage = 9
	
	available_keywords[9].interact_function = func single_target_damage(
		damage:int = chosen_spell_words[cast_lane_helper].damage, damage_modifier:int = chosen_spell_words[cast_lane_helper].damage_modifier): 
			threat_lanes[cast_lane_helper].current_health -= damage + damage_modifier
	
	available_keywords[9].ability = func ability()->String:
		return "Deal " + str(hover_text.damage + hover_text.damage_modifier) + " damage to the threat in this lane"
	
	
	
	#Creates a words scene and passes in array of Keywords
	var new_word_generator = word_generator.instantiate()
	$VBoxContainer.add_child(new_word_generator)
	new_word_generator.setup(available_keywords)
	
	$VBoxContainer/SpellHBox/Word1.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word1))
	$VBoxContainer/SpellHBox/Word2.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word2))
	$VBoxContainer/SpellHBox/Word3.pressed.connect(spell_word_pressed.call.bind($VBoxContainer/SpellHBox/Word3))

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("spacebar") and not lock:
		lock = true
		end_turn()
	if Input.is_action_just_pressed("1") and not lock:
		if hover_text != null:
			if hover_text.spell_word:
				if not hover_text.disabled:
					chosen_spell_words[0] = hover_text
					self.get_node("VBoxContainer/Words").meta_disabled(hover_text.bbcode_tag)
	if Input.is_action_just_pressed("2") and not lock:
		if hover_text != null:
			if hover_text.spell_word:
				if not hover_text.disabled:
					chosen_spell_words[1] = hover_text
					self.get_node("VBoxContainer/Words").meta_disabled(hover_text.bbcode_tag)
	if Input.is_action_just_pressed("3") and not lock:
		if hover_text != null:
			if hover_text.spell_word:
				if not hover_text.disabled:
					chosen_spell_words[2] = hover_text
					self.get_node("VBoxContainer/Words").meta_disabled(hover_text.bbcode_tag)
				
	
	$Casting_spells.visible = lock
	casting_timer += delta
	$Casting_spells.visible_ratio = 0.882 + ((casting_timer)*0.125)
	if casting_timer > 1.25:
		casting_timer = 0
	if not lock:
		for i in chosen_spell_words.size():
				chosen_spell_words[i].modify(i)
	
	if hover_text != null:
		$Ability_text.visible = true
		$Ability_text.text = hover_text.get_ability()
	elif chosen_spell_hover != "":
		match chosen_spell_hover:
			"Word1": hover_text = chosen_spell_words[0]
			"Word2": hover_text = chosen_spell_words[1]
			"Word3": hover_text = chosen_spell_words[2]
		
		$Ability_text.text = hover_text.get_ability()
		
		if $Ability_text.text == "":
			$Ability_text.visible = false
			hover_text = null
		else:
			$Ability_text.visible = true
	else:
		$Ability_text.visible = false

		
	$Ability_text.global_position = get_global_mouse_position() - Vector2(0, 40)
	
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
			chosen_spell_words[keyword].interact()
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
