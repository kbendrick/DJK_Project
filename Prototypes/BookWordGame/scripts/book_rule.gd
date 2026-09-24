class_name BookRule
extends Resource

@export var display_name := "Book Rule"
@export_multiline var description := ""
@export_range(0, 20) var penalty_amount := 1
@export_range(0, 10) var book_moves_per_turn := 2

var penalty_resource := "Sanity"

func collect_matches(_model: LetterGridModel) -> Array:
	return []


func calculate_book_turn(_model: LetterGridModel, _rng: RandomNumberGenerator) -> Array[Array]:
	return []


func take_book_turn(_model: LetterGridModel, _moves: Array) -> Array[String]:
	return []
