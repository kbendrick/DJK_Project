class_name BookRule
extends Resource

@export var display_name := "Book Rule"
@export_multiline var description := ""
@export_range(0, 20) var penalty_amount := 1
@export_range(0, 10) var book_moves_per_turn := 2

var penalty_resource := "Sanity"

func count_matches(_model: LetterGridModel) -> int:
	return 0


func take_book_turn(_model: LetterGridModel, _rng: RandomNumberGenerator) -> Array[String]:
	return []
