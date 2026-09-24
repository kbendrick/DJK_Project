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


func collect_matches(model: LetterGridModel) -> Array[Vector2i]:
	var matches: Array[Vector2i] = []

	# Check grid for adjacent pairs of vowels
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			# If letter isn't a vowel, continue through loop; otherwise, check letter immediately to the right and down for vowels and add to match count if it is a vowel
			if not _is_vowel(model.get_letter(Vector2i(x, y))):
				continue
			if x + 1 < LetterGridModel.GRID_SIZE and _is_vowel(model.get_letter(Vector2i(x + 1, y))):
				if not matches.has(Vector2i(x, y)):
					matches.append(Vector2i(x, y))
				if not matches.has(Vector2i(x + 1, y)):
					matches.append(Vector2i(x + 1, y))
			if y + 1 < LetterGridModel.GRID_SIZE and _is_vowel(model.get_letter(Vector2i(x, y + 1))):
				if not matches.has(Vector2i(x, y)):
					matches.append(Vector2i(x, y))
				if not matches.has(Vector2i(x, y + 1)):
					matches.append(Vector2i(x, y + 1))
	return matches


func calculate_book_turn(model: LetterGridModel, rng: RandomNumberGenerator) -> Array[Array]:
	var planned_turns: Array[Array] = []
	if action_cycle.is_empty():
		return planned_turns

	for move_index in book_moves_per_turn:
		# Sets action variable to where the current cursor is, then moves the cursor forward
		var action := action_cycle[_action_cursor % action_cycle.size()]
		_action_cursor += 1
		var turn := _prepare_action(action, model, rng)
		if turn.is_empty():
			turn = _prepare_action("substitution", model, rng)
		if not turn.is_empty():
			planned_turns.append(turn)
	return planned_turns


func take_book_turn(model: LetterGridModel, moves: Array) -> Array[String]:
	var results: Array[String] = []
	if moves.is_empty():
		return results

	for move_index in moves:
		# Sets action variable to where the current cursor is, then moves the cursor forward
		var result := _perform_action(model, move_index)
		if result.is_empty():
			result = _perform_action(model, ["substitution", Vector2i(0,0), "O"])
		if not result.is_empty():
			results.append(result)
	return results


func _prepare_action(action: String, model: LetterGridModel, rng: RandomNumberGenerator) -> Array:
	match action:
		"substitution":
			return _prepare_substitute_toward_vowels(model, rng)
		"transposition":
			return _prepare_transpose_toward_vowels(model)
		"insertion":
			return _prepare_insert_vowel(model, rng)
		"deletion":
			return _prepare_delete_consonant(model, rng)
	return []


func _perform_action(model: LetterGridModel, action_instructions: Array) -> String:
	match action_instructions[0]:
		"substitution":
			return _substitute_toward_vowels(model, action_instructions[1], action_instructions[2])
		"transposition":
			return _transpose_toward_vowels(model, action_instructions[1], action_instructions[2])
		"insertion":
			return _insert_vowel(model, action_instructions[1], action_instructions[2])
		"deletion":
			return _delete_consonant(model, action_instructions[1], action_instructions[2]) #selected_cell, rng
	return ""


func _prepare_substitute_toward_vowels(model: LetterGridModel, rng: RandomNumberGenerator) -> Array:
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			var cell := Vector2i(x, y)
			if _is_vowel(model.get_letter(cell)):
				continue
			if _has_vowel_neighbor(model, cell):
				var new_letter := model.random_letter(rng, VOWELS)
				return ["substitution",cell, new_letter]
	return []


func _substitute_toward_vowels(model: LetterGridModel, cell: Vector2i, new_letter: String) -> String:
	if model.is_valid_cell(cell):
		model.set_letter(cell, new_letter)
		return "The book substituted %s at (%d, %d)." % [new_letter, cell.x + 1, cell.y + 1]
	return ""


func _prepare_transpose_toward_vowels(model: LetterGridModel) -> Array:
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
				var before := collect_matches(model).size()
				model.transpose(vowel_cell, consonant_cell)

				# If there are more matches than before, bring the cells back to normal and return the cells that will be transposed
				if collect_matches(model).size() > before:
					model.transpose(vowel_cell, consonant_cell)
					return ["transposition",vowel_cell, consonant_cell]

				# If there are less matches than before, bring cells back to normal and continue through the loop
				model.transpose(vowel_cell, consonant_cell)
	return []


func _transpose_toward_vowels(model: LetterGridModel, vowel_cell: Vector2i, consonant_cell: Vector2i) -> String:
	if model.is_valid_cell(vowel_cell) and model.is_valid_cell(consonant_cell):
		model.transpose(vowel_cell, consonant_cell)
		return "The book transposed adjacent letters at (%d, %d) and (%d, %d)." % [vowel_cell.x + 1, vowel_cell.y + 1, consonant_cell.x + 1, consonant_cell.y + 1]
	return ""


func _prepare_insert_vowel(model: LetterGridModel, rng: RandomNumberGenerator) -> Array:
	# Search for a cell that has a neighboring vowel
	for y in LetterGridModel.GRID_SIZE:
		for x in LetterGridModel.GRID_SIZE:
			var cell := Vector2i(x, y)
			if _has_vowel_neighbor(model, cell):
				var new_letter := model.random_letter(rng, VOWELS)
				return ["insertion", cell, new_letter]
	return []


func _insert_vowel(model: LetterGridModel, cell: Vector2i, new_letter: String) -> String:
	# Search for a cell that has a neighboring vowel
	if model.is_valid_cell(cell):
		model.insert_at(cell, new_letter)
		return "The book inserted %s at (%d, %d)." % [new_letter, cell.x + 1, cell.y + 1]
	return ""


func _prepare_delete_consonant(model: LetterGridModel, rng: RandomNumberGenerator) -> Array:
	var consonant_cells: Array[Vector2i] = []

	# Iterate over grid, adding all consonant cell locations
	for index in LetterGridModel.LETTER_COUNT:
		var cell := model.index_to_cell(index)
		if not _is_vowel(model.get_letter(cell)):
			consonant_cells.append(cell)
	
	# Choose a random cell that has a consonant, and delete
	var selected_cell: Vector2i = consonant_cells[rng.randi_range(0, consonant_cells.size()-1)]
	return ["deletion", selected_cell, rng]


func _delete_consonant(model: LetterGridModel, selected_cell: Vector2i, rng: RandomNumberGenerator) -> String:
	if model.is_valid_cell(selected_cell):
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