class_name DrewStew
extends Control

# The grid shows five letters from each ten-letter column.
const GRID_SIZE := 5
const LETTERS_PER_COLUMN := 10
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Add or remove five-letter words from this list in the Inspector.
@export var valid_words := PackedStringArray([
	"APPLE",
	"BREAD",
	"CLOUD",
	"DREAM",
	"MUSIC"
])

# Every time this many seconds passes, all columns move one position.
@export_range(0.05, 5.0, 0.05) var seconds_per_step := 0.5

@onready var letter_grid: GridContainer = $Center/Panel/Margin/Layout/LetterGrid
@onready var status_label: Label = $Center/Panel/Margin/Layout/StatusLabel
@onready var pause_button: Button = $Center/Panel/Margin/Layout/Controls/PauseButton
@onready var reroll_button: Button = $Center/Panel/Margin/Layout/Controls/RerollButton

# Each entry is one vertical column containing ten letters.
# Example: letter_columns[2] is the third vertical column.
var letter_columns: Array = []

# An offset determines which five letters from each column are visible.
var column_offsets: Array[int] = [0, 0, 0, 0, 0]

# Buttons are stored row-by-row: five buttons for row 0, then row 1, etc.
var letter_buttons: Array[Button] = []

var elapsed_time := 0.0
var is_paused := false
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	_create_grid_buttons()
	_create_random_columns()
	_update_grid()

	pause_button.pressed.connect(_toggle_pause)
	reroll_button.pressed.connect(_reroll_letters)


func _process(delta: float) -> void:
	if is_paused:
		return

	elapsed_time += delta

	# The while loop keeps the rotation accurate even if one frame is slow.
	while elapsed_time >= seconds_per_step:
		elapsed_time -= seconds_per_step
		_rotate_columns_one_position()
		_update_grid()


func _create_grid_buttons() -> void:
	for index in GRID_SIZE * GRID_SIZE:
		var button := Button.new()
		button.custom_minimum_size = Vector2(90, 90)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 34)

		letter_grid.add_child(button)
		letter_buttons.append(button)


func _create_random_columns() -> void:
	letter_columns.clear()
	column_offsets = [0, 0, 0, 0, 0]

	for column_index in GRID_SIZE:
		var new_column: Array[String] = []

		for letter_index in LETTERS_PER_COLUMN:
			new_column.append(_random_letter())

		letter_columns.append(new_column)


func _random_letter() -> String:
	var random_index := random.randi_range(0, ALPHABET.length() - 1)
	return ALPHABET[random_index]


func _rotate_columns_one_position() -> void:
	for column_index in GRID_SIZE:
		if column_index % 2 == 0:
			# Columns 1, 3, and 5 move down. The former final
			# value wraps around and becomes the new top value.
			column_offsets[column_index] = wrapi(
				column_offsets[column_index] - 1,
				0,
				LETTERS_PER_COLUMN
			)
		else:
			# Columns 2 and 4 move upward.
			column_offsets[column_index] = wrapi(
				column_offsets[column_index] + 1,
				0,
				LETTERS_PER_COLUMN
			)


func _update_grid() -> void:
	# First update the 25 displayed letters.
	for row_index in GRID_SIZE:
		for column_index in GRID_SIZE:
			var button_index := row_index * GRID_SIZE + column_index
			var letter_index := wrapi(
				row_index + column_offsets[column_index],
				0,
				LETTERS_PER_COLUMN
			)

			letter_buttons[button_index].text = letter_columns[column_index][letter_index]

	_check_rows_for_words()


func _check_rows_for_words() -> void:
	var found_words: Array[String] = []

	for row_index in GRID_SIZE:
		var row_word := ""

		for column_index in GRID_SIZE:
			var button_index := row_index * GRID_SIZE + column_index
			row_word += letter_buttons[button_index].text

		var is_valid_word := valid_words.has(row_word)

		for column_index in GRID_SIZE:
			var button_index := row_index * GRID_SIZE + column_index
			letter_buttons[button_index].modulate = (
				Color(0.55, 1.0, 0.55)
				if is_valid_word
				else Color.WHITE
			)

		if is_valid_word:
			found_words.append(row_word)

	if found_words.is_empty():
		status_label.text = "No five-letter words currently visible."
	else:
		status_label.text = "Found: " + ", ".join(found_words)


func _toggle_pause() -> void:
	is_paused = not is_paused
	pause_button.text = "RESUME" if is_paused else "PAUSE"


func _reroll_letters() -> void:
	elapsed_time = 0.0
	_create_random_columns()
	_update_grid()
