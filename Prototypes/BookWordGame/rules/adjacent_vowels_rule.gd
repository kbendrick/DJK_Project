class_name AdjacentVowelsRule
extends BookRule

const VOWELS := "AEIOU"

# Possible book actions
@export var action_cycle := PackedStringArray(["substitution", "transposition", "insertion", "deletion"])

# Variable to store where book is acting upon the grid
var _action_cursor := 0


func _init() -> void:
	display_name = "Crowded Vowels"
	description = "Vowels cannot be horizontally or vertically adjacent."
	penalty_resource = "Sanity"
	penalty_amount = 1
	book_moves_per_turn = 2


func count_matches(model: LetterGridModel) -> int:
	var matches := 0

	# Check grid for adjacent pairs of vowels
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			# If letter isn't a vowel, continue through loop; otherwise, check letter immediately to the right and down for vowels and add to match count if it is a vowel
			if not _is_vowel(model.get_letter(Vector2i(x, y))):
				continue
			if x + 1 < LetterGridModel.GRID_SIZE and _is_vowel(model.get_letter(Vector2i(x + 1, y))):
				matches += 1
			if y + 1 < LetterGridModel.GRID_SIZE and _is_vowel(model.get_letter(Vector2i(x, y + 1))):
				matches += 1
	return matches


func take_book_turn(model: LetterGridModel, rng: RandomNumberGenerator) -> Array[String]:
	var results: Array[String] = []
	if action_cycle.is_empty():
		return results

	for move_index in book_moves_per_turn:
		# Sets action variable to where the current cursor is, then moves the cursor forward
		var action := action_cycle[_action_cursor % action_cycle.size()]
		_action_cursor += 1
		var result := _perform_action(action, model, rng)
		if result.is_empty():
			result = _perform_action("substitution", model, rng)
		if not result.is_empty():
			results.append(result)
	return results


func _perform_action(action: String, model: LetterGridModel, rng: RandomNumberGenerator) -> String:
	match action:
		"substitution":
			return _substitute_toward_vowels(model, rng)
		"transposition":
			return _transpose_toward_vowels(model)
		"insertion":
			return _insert_vowel(model, rng)
		"deletion":
			return _delete_consonant(model, rng)
	return ""


func _substitute_toward_vowels(model: LetterGridModel, rng: RandomNumberGenerator) -> String:
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			var cell := Vector2i(x, y)
			if _is_vowel(model.get_letter(cell)):
				continue
			if _has_vowel_neighbor(model, cell):
				var new_letter := model.random_letter(rng, VOWELS)
				model.set_letter(cell, new_letter)
				return "The book substituted %s at (%d, %d)." % [new_letter, x + 1, y + 1]
	return ""


func _transpose_toward_vowels(model: LetterGridModel) -> String:
	var directions := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			var vowel_cell := Vector2i(x, y)
			if not _is_vowel(model.get_letter(vowel_cell)):
				continue
			for direction in directions:
				var consonant_cell: Vector2i = vowel_cell + direction
				if not model.is_valid_cell(consonant_cell) or _is_vowel(model.get_letter(consonant_cell)):
					continue
				var before := count_matches(model)
				model.transpose(vowel_cell, consonant_cell)
				if count_matches(model) > before:
					return "The book transposed adjacent letters at (%d, %d) and (%d, %d)." % [vowel_cell.x + 1, vowel_cell.y + 1, consonant_cell.x + 1, consonant_cell.y + 1]
				model.transpose(vowel_cell, consonant_cell)
	return ""


func _insert_vowel(model: LetterGridModel, rng: RandomNumberGenerator) -> String:
	# Search for a cell that has a neighboring vowel
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			var cell := Vector2i(x, y)
			if _has_vowel_neighbor(model, cell):
				var new_letter := model.random_letter(rng, VOWELS)
				model.insert_at(cell, new_letter)
				return "The book inserted %s at (%d, %d)." % [new_letter, x + 1, y + 1]
	return ""


func _delete_consonant(model: LetterGridModel, rng: RandomNumberGenerator) -> String:
	var consonant_cells: Array[Vector2i] = []

	# Iterate over grid, adding all consonant cell locations
	for index in LetterGridModel.LETTER_COUNT:
		var cell := model.index_to_cell(index)
		if not _is_vowel(model.get_letter(cell)):
			consonant_cells.append(cell)
	
	# Choose a random cell that has a consonant, and delete
	var selected_cell: Vector2i = consonant_cells[rng.randi_range(0, consonant_cells.size()-1)]
	model.delete_at(selected_cell, rng)
	return "The book deleted the letter at (%d, %d)." % [selected_cell.x + 1, selected_cell.y + 1]


# Checks the adjancent letters for vowels
func _has_vowel_neighbor(model: LetterGridModel, cell: Vector2i) -> bool:
	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var neighbor: Vector2i = cell + direction
		if model.is_valid_cell(neighbor) and _is_vowel(model.get_letter(neighbor)):
			return true
	return false


func _is_vowel(letter: String) -> bool:
	return VOWELS.contains(letter)
