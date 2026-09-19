class_name LetterGridModel
extends RefCounted

const GRID_SIZE := 8
const LETTER_COUNT := GRID_SIZE * GRID_SIZE
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var letters: Array = []


func randomize_grid(rng: RandomNumberGenerator) -> void:
	letters.clear()
	for row_index in GRID_SIZE:
		var row: Array[String] = []
		for column_index in GRID_SIZE:
			row.append(random_letter(rng))
		letters.append(row)


func copy_nested_array() -> Array:
	var result: Array = []
	for row in letters:
		result.append(row.duplicate())
	return result


func random_letter(rng: RandomNumberGenerator, pool: String = ALPHABET) -> String:
	return pool[rng.randi_range(0, pool.length() - 1)]


func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE


func get_letter(cell: Vector2i) -> String:
	if not is_valid_cell(cell):
		return ""
	return letters[cell.y][cell.x]


func set_letter(cell: Vector2i, value: String) -> bool:
	if not is_valid_cell(cell) or value.is_empty():
		return false
	letters[cell.y][cell.x] = value.left(1).to_upper()
	return true


func substitute(cell: Vector2i, rng: RandomNumberGenerator) -> bool:
	if not is_valid_cell(cell):
		return false
	var old_letter := get_letter(cell)
	var new_letter := random_letter(rng)
	while new_letter == old_letter:
		new_letter = random_letter(rng)
	return set_letter(cell, new_letter)


func delete_at(cell: Vector2i, rng: RandomNumberGenerator) -> bool:
	if not is_valid_cell(cell):
		return false
	var flat := flatten()
	flat.remove_at(cell_to_index(cell))
	flat.append(random_letter(rng))
	_rebuild_from_flat(flat)
	return true


func insert_at(cell: Vector2i, letter: String) -> bool:
	if not is_valid_cell(cell) or letter.is_empty():
		return false
	var flat := flatten()
	flat.insert(cell_to_index(cell), letter.left(1).to_upper())
	flat.resize(LETTER_COUNT)
	_rebuild_from_flat(flat)
	return true


func transpose(first: Vector2i, second: Vector2i) -> bool:
	if not is_valid_cell(first) or not is_valid_cell(second):
		return false
	if absi(first.x - second.x) + absi(first.y - second.y) != 1:
		return false
	var temporary := get_letter(first)
	set_letter(first, get_letter(second))
	set_letter(second, temporary)
	return true


func flatten() -> Array[String]:
	var result: Array[String] = []
	for row in letters:
		for letter in row:
			result.append(letter)
	return result


func cell_to_index(cell: Vector2i) -> int:
	return cell.y * GRID_SIZE + cell.x


func index_to_cell(index: int) -> Vector2i:
	return Vector2i(index % GRID_SIZE, index / GRID_SIZE)


func find_word_positions(word: String) -> Array[Vector2i]:
	var normalized := word.strip_edges().to_upper()
	var found: Array[Vector2i] = []
	if normalized.is_empty() or normalized.length() > GRID_SIZE:
		return found

	for y in GRID_SIZE:
		for x in range(GRID_SIZE - normalized.length() + 1):
			var matches := true
			for offset in normalized.length():
				if letters[y][x + offset] != normalized[offset]:
					matches = false
					break
			if matches:
				for offset in normalized.length():
					found.append(Vector2i(x + offset, y))
				return found

	for x in GRID_SIZE:
		for y in range(GRID_SIZE - normalized.length() + 1):
			var matches := true
			for offset in normalized.length():
				if letters[y + offset][x] != normalized[offset]:
					matches = false
					break
			if matches:
				for offset in normalized.length():
					found.append(Vector2i(x, y + offset))
				return found

	return found


func contains_word(word: String) -> bool:
	return not find_word_positions(word).is_empty()


func _rebuild_from_flat(flat: Array[String]) -> void:
	letters.clear()
	for y in GRID_SIZE:
		var row: Array[String] = []
		for x in GRID_SIZE:
			row.append(flat[y * GRID_SIZE + x])
		letters.append(row)
