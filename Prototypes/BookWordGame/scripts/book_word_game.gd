class_name BookWordGame
extends Node2D

# Sets up constants in the Phase enumeration
enum Phase { OPENING, PLAYER, BOOK, VICTORY }

# Variable for words that player must create in the book
@export var target_words := PackedStringArray(["BOOK"])

# Variables for starting player resources
@export_range(1, 20) var starting_action_points := 3
@export_range(0, 999) var starting_sanity := 10
@export_range(0, 999) var starting_savvy := 20
@export_range(0, 999) var starting_insight := 20
@export_range(0, 999) var gold_reward := 25

# Variables to load rules and extra abilities for the specific book puzzle
@export var book_rule_script: Script = preload("res://Prototypes/BookWordGame/rules/adjacent_vowels_rule.gd")
var book_rule: BookRule
@export var extra_abilities: Array[BookAbility] = []

@export var button_font_size = 16

# Variables to connect to various elements of the book
@onready var opening_sprite: AnimatedSprite2D = $BookOpening
@onready var interface: Control = $Interface
@onready var resource_label: Label = $Interface/Center/BookSpread/LeftPage/PageMargin/LeftContent/ResourceLabel
@onready var goal_label: Label = $Interface/Center/BookSpread/LeftPage/PageMargin/LeftContent/GoalLabel
@onready var grid_container: GridContainer = $Interface/Center/BookSpread/LeftPage/PageMargin/LeftContent/LetterGrid
@onready var turn_label: Label = $Interface/Center/BookSpread/RightPage/PageMargin/RightContent/TurnLabel
@onready var rule_label: Label = $Interface/Center/BookSpread/RightPage/PageMargin/RightContent/RuleLabel
@onready var ability_container: VBoxContainer = $Interface/Center/BookSpread/RightPage/PageMargin/RightContent/AbilityList
@onready var status_label: Label = $Interface/Center/BookSpread/RightPage/PageMargin/RightContent/StatusLabel
@onready var log_label: RichTextLabel = $Interface/Center/BookSpread/RightPage/PageMargin/RightContent/Log
@onready var end_turn_button: Button = $Interface/Center/BookSpread/RightPage/PageMargin/RightContent/EndTurnButton
@onready var letter_picker: Control = $LetterPicker
@onready var letter_picker_grid: GridContainer = $LetterPicker/Center/Panel/Margin/Content/Letters
@onready var victory_overlay: Control = $VictoryOverlay
@onready var victory_summary: Label = $VictoryOverlay/Center/Panel/Margin/Content/Summary
@onready var keep_page_check: CheckButton = $VictoryOverlay/Center/Panel/Margin/Content/KeepPage


var grid_model := LetterGridModel.new()
var rng := RandomNumberGenerator.new()
var abilities: Array[BookAbility] = []
var grid_buttons: Array[Button] = []
var ability_buttons: Dictionary = {}
var selected_cells: Array[Vector2i] = []
var active_ability: BookAbility
var phase := Phase.OPENING

var maximum_action_points := 3
var action_points := 3
var sanity := 0
var savvy := 0
var insight := 0
var gold := 0
var round_number := 1
var savvy_discount := 0
var insight_discount := 0
var earned_pages: Array = []


func _ready() -> void:
	# Randomize book RNG and set player stats for the book puzzle
	rng.randomize()
	maximum_action_points = starting_action_points
	savvy = starting_savvy
	insight = starting_insight
	sanity = starting_sanity

	#? Load a book rule if none is set yet?
	if book_rule == null:
		book_rule = book_rule_script.new() as BookRule
		if book_rule == null:
			print("The selected script does not extend BookRule.")
			return
		book_rule.penalty_resource = "Sanity"
		book_rule.penalty_amount = 1
		book_rule.book_moves_per_turn = 2
	else:
		book_rule = book_rule.duplicate(true)

	# Sets up both standard and extra player abilities
	_build_abilities()

	# Sets up letter grid on left page
	_build_grid_buttons()
	_build_ability_buttons()
	_build_letter_picker()
	#_connect_reward_buttons()
	grid_model.randomize_grid(rng)
	end_turn_button.pressed.connect(_end_player_turn)
	opening_sprite.animation_finished.connect(_on_book_opened)
	interface.hide()
	letter_picker.hide()
	victory_overlay.hide()
	opening_sprite.play(&"open")


func _build_abilities() -> void:
	# Sets up standard player abilities
	abilities.assign([
		TranspositionAbility.new(),
		DeletionAbility.new(),
		SubstitutionAbility.new(),
		InsertionAbility.new()
	])
	# Checks for any extra abilities and sets them up as well
	for extra_ability in extra_abilities:
		if extra_ability != null:
			abilities.append(extra_ability.duplicate(true))


func _build_grid_buttons() -> void:
	# Clears any existing letters in the letter grid
	for child in grid_container.get_children():
		child.queue_free()
	
	# Clears grid_buttons array for new buttons to be added
	grid_buttons.clear()

	# For every cell in the grid, create a new button that returns the cell's coordinates
	for index in LetterGridModel.LETTER_COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(72, 72)
		button.add_theme_font_size_override("font_size", 30)
		button.tooltip_text = "Row %d, Column %d" % [index / LetterGridModel.GRID_SIZE + 1, index % LetterGridModel.GRID_SIZE + 1]
		var cell := grid_model.index_to_cell(index)
		button.pressed.connect(_on_grid_cell_pressed.bind(cell))
		grid_container.add_child(button)
		grid_buttons.append(button)


func _build_ability_buttons() -> void:
	# Clears any existing ability buttons
	for child in ability_container.get_children():
		child.queue_free()

	# Clears ability_buttons dictionary for new buttons to be added
	ability_buttons.clear()

	# For every ability in the abilities array, create a new button that returns the ability
	for ability in abilities:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 96)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_ability_pressed.bind(ability))
		button.add_theme_font_size_override("font_size", button_font_size)
		ability_container.add_child(button)
		ability_buttons[ability] = button


# Creates a letter picker for when player chooses specific letters
func _build_letter_picker() -> void:
	# Clears any existing buttons in the letter_picker grid
	for child in letter_picker_grid.get_children():
		child.queue_free()

	# Creates individual buttons for each letter of the letter picker
	for character in LetterGridModel.ALPHABET:
		var button := Button.new()
		button.text = character
		button.custom_minimum_size = Vector2(64, 64)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(_on_letter_chosen.bind(character))
		letter_picker_grid.add_child(button)
	
	# Binds a cancel button to cancel the letter picking process
	$LetterPicker/Center/Panel/Margin/Content/Cancel.pressed.connect(_cancel_letter_picker)


#func _connect_reward_buttons() -> void:
	#upgrade_action_button.pressed.connect(_apply_upgrade.bind(&"actions"))
	#upgrade_savvy_button.pressed.connect(_apply_upgrade.bind(&"savvy"))
	#upgrade_insight_button.pressed.connect(_apply_upgrade.bind(&"insight"))


func _on_book_opened() -> void:
	interface.show()
	_start_player_turn()
	_add_log("The book opens. Create %s horizontally or vertically." % ", ".join(target_words))


# Sets Phase to player, resets action points, clears any ability or letter selections
func _start_player_turn() -> void:
	phase = Phase.PLAYER
	action_points = maximum_action_points
	active_ability = null
	selected_cells.clear()
	status_label.text = "Choose an ability, then select letter cells."
	_refresh_all()


# When an ability is pressed, check that it's the player's turn and that the player has the resources
func _on_ability_pressed(ability: BookAbility) -> void:
	if phase != Phase.PLAYER:
		return
	if not _can_pay_for(ability):
		status_label.text = "You cannot afford %s." % ability.display_name
		return

	# Set active ability and clear the selected cells array
	active_ability = ability
	selected_cells.clear()
	status_label.text = "%s selected: choose %d letter%s." % [ability.display_name, ability.required_targets, "" if ability.required_targets == 1 else "s"]
	_refresh_grid()
	_refresh_abilities()


# When a grid cell is pressed, pass in an XY coordinate
func _on_grid_cell_pressed(cell: Vector2i) -> void:
	# Do not select cell if it's already selected, if there's no active ability, and if it's not the player's turn
	if phase != Phase.PLAYER or active_ability == null:
		status_label.text = "Choose an ability before selecting a letter."
		return
	if not active_ability.is_valid_next_target(grid_model, selected_cells, cell):
		status_label.text = "That cell is not a valid next target for %s." % active_ability.display_name
		return
	selected_cells.append(cell)
	_refresh_grid()

	# If player needs to select more cells than currently selected, give a notice
	if selected_cells.size() < active_ability.required_targets:
		status_label.text = "Choose one adjacent letter."
		return
	
	# Opne the letter picker if the ability allows the player to choose a letter
	if active_ability.requires_letter_choice:
		letter_picker.show()
		return
	_execute_active_ability("")


func _on_letter_chosen(letter: String) -> void:
	letter_picker.hide()
	_execute_active_ability(letter)


func _cancel_letter_picker() -> void:
	letter_picker.hide()
	selected_cells.clear()
	_refresh_grid()
	status_label.text = "Insertion cancelled."


func _execute_active_ability(letter_choice: String) -> void:
	# If there's no active ability or you can't pay for it, clear all selected sells
	if active_ability == null or not _can_pay_for(active_ability):
		selected_cells.clear()
		_refresh_all()
		return
	var used_ability := active_ability

	# Depends on book ability's apply function
	if not used_ability.apply(grid_model, selected_cells, letter_choice, rng):
		status_label.text = "%s could not be applied." % used_ability.display_name
		selected_cells.clear()
		_refresh_grid()
		return

	# Subtract the ability AP/savvy/insight costs from player resources, announce success, reset active_ability and clear cells
	action_points -= used_ability.action_point_cost
	savvy -= _savvy_cost(used_ability)
	insight -= _insight_cost(used_ability)
	_add_log("You used %s." % used_ability.display_name)
	active_ability = null
	selected_cells.clear()
	status_label.text = "%s complete." % used_ability.display_name

	_refresh_all()

	# Check victory conditions
	if _all_goals_complete():
		_show_victory()
	elif action_points <= 0:
		call_deferred("_end_player_turn")


func _end_player_turn() -> void:
	# Double-check that it's not the player's turn
	if phase != Phase.PLAYER:
		return

	# Change to book's turn and clear the usual: active ability/selected cells/letter picker
	phase = Phase.BOOK
	active_ability = null
	selected_cells.clear()
	letter_picker.hide()
	status_label.text = "The book takes its turn"
	_refresh_all()

	#? Wait half a second?
	await get_tree().create_timer(0.45).timeout

	# Check for any cases where the book rule can affect the player/grid state
	var violations := book_rule.count_matches(grid_model)


	if violations > 0 and book_rule.penalty_amount > 0:
		sanity = maxi(0, sanity - book_rule.penalty_amount)
		_add_log("%s found %d violation%s. You lose %d %s." % [book_rule.display_name, violations, "" if violations == 1 else "s", book_rule.penalty_amount, book_rule.penalty_resource])
	else:
		_add_log("The page satisfies %s. No penalty." % book_rule.display_name)

	var book_actions := book_rule.take_book_turn(grid_model, rng)
	for action_text in book_actions:
		_add_log(action_text)
	_refresh_all()
	await get_tree().create_timer(0.45).timeout

	if _all_goals_complete():
		_show_victory()
		return
	round_number += 1
	_start_player_turn()


# Show victory screen, grant gold, reset active ability, selected cells. Show victory overlay
func _show_victory() -> void:
	phase = Phase.VICTORY
	gold += gold_reward
	active_ability = null
	selected_cells.clear()
	keep_page_check.button_pressed = true
	victory_summary.text = "All words are on the page.\n\nReward: %d gold\nTotal gold: %d\n\nChoose one page upgrade:" % [gold_reward, gold]
	victory_overlay.show()
	_refresh_all()


func _apply_upgrade(upgrade_id: StringName) -> void:
	if phase != Phase.VICTORY:
		return
	if keep_page_check.button_pressed:
		earned_pages.append(grid_model.copy_nested_array())
	match upgrade_id:
		&"actions":
			maximum_action_points += 1
			_add_log("Page upgrade: +1 maximum action point.")
		&"savvy":
			savvy_discount += 1
			_add_log("Page upgrade: all ability Savvy costs reduced by 1.")
		&"insight":
			insight_discount += 1
			_add_log("Page upgrade: all ability Insight costs reduced by 1.")
	victory_overlay.hide()
	grid_model.randomize_grid(rng)
	round_number += 1
	_start_player_turn()


func _refresh_all() -> void:
	_refresh_resources()
	_refresh_grid()
	_refresh_goals()
	_refresh_abilities()
	end_turn_button.disabled = phase != Phase.PLAYER


# Refreshes display labels for player resources, as well as the turn counter and rule displays
func _refresh_resources() -> void:
	resource_label.text = "AP  %d / %d     SAVVY  %d     INSIGHT  %d     GOLD  %d     SANITY  %d" % [action_points, maximum_action_points, savvy, insight, gold, sanity]
	turn_label.text = "ROUND %d   •   %s TURN" % [round_number, "PLAYER" if phase == Phase.PLAYER else "BOOK"]
	rule_label.text = "BOOK RULE — %s\n%s\nPenalty: %d %s" % [book_rule.display_name, book_rule.description, book_rule.penalty_amount, book_rule.penalty_resource]


func _refresh_grid() -> void:
	# Creates a variable for cells that have a completed word objective inside
	var completed_cells: Array[Vector2i] = []

	# Checks to see if any of the target words have been completed
	for word in target_words:
		completed_cells.append_array(grid_model.find_word_positions(word))
	
	# Updates button text and color to match any changes from ability usage or no longer being player turn
	for index in grid_buttons.size():
		var button := grid_buttons[index]
		var cell := grid_model.index_to_cell(index)
		button.text = grid_model.get_letter(cell)
		button.disabled = phase != Phase.PLAYER

		# If cell is selected, color it yellow; if it's part of a completed word, color it green
		if selected_cells.has(cell):
			button.modulate = Color("ffd166")
		elif completed_cells.has(cell):
			button.modulate = Color("8bd17c")
		else:
			button.modulate = Color.WHITE


# Displays target word with either an empty circle or a checkmark depending on if the target word is found
func _refresh_goals() -> void:
	var pieces: Array[String] = []
	for word in target_words:
		pieces.append("✓ %s" % word if grid_model.contains_word(word) else "○ %s" % word)
	goal_label.text = "TARGET WORDS   " + "     ".join(pieces)


# Updates ability information and color based on player turn and if ability is currently active
func _refresh_abilities() -> void:
	for ability in abilities:
		var button: Button = ability_buttons[ability]
		button.text = "%s  —  %d AP, %d Savvy, %d Insight\n%s" % [ability.display_name, ability.action_point_cost, _savvy_cost(ability), _insight_cost(ability), ability.description]
		button.disabled = phase != Phase.PLAYER or not _can_pay_for(ability)
		button.modulate = Color("ffd166") if active_ability == ability else Color.WHITE


func _can_pay_for(ability: BookAbility) -> bool:
	return action_points >= ability.action_point_cost and savvy >= _savvy_cost(ability) and insight >= _insight_cost(ability)


func _savvy_cost(ability: BookAbility) -> int:
	return maxi(0, ability.savvy_cost - savvy_discount)


func _insight_cost(ability: BookAbility) -> int:
	return maxi(0, ability.insight_cost - insight_discount)


func _all_goals_complete() -> bool:
	# If there's more than one word in the target_words array, goals aren't complete
	if target_words.size() != 1:
		return false
	
	# Check if the grid contains the target word/words
	for word in target_words:
		if not grid_model.contains_word(word):
			return false
	return true


func _add_log(message: String) -> void:
	log_label.text = "• %s\n" % message
	#log_label.scroll_to_line(maxi(0, log_label.get_line_count() - 1))
