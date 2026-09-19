class_name TranspositionAbility
extends BookAbility


func _init() -> void:
	ability_id = &"transposition"
	display_name = "Transposition"
	description = "Exchange two horizontally or vertically adjacent letters."
	action_point_cost = 2
	savvy_cost = 1
	insight_cost = 0
	required_targets = 2


func is_valid_next_target(_model: LetterGridModel, current_targets: Array[Vector2i], cell: Vector2i) -> bool:
	if current_targets.is_empty():
		return true
	if current_targets.size() != 1:
		return false
	var first := current_targets[0]
	return absi(first.x - cell.x) + absi(first.y - cell.y) == 1


func apply(model: LetterGridModel, targets: Array[Vector2i], _letter_choice: String, _rng: RandomNumberGenerator) -> bool:
	return targets.size() == 2 and model.transpose(targets[0], targets[1])
