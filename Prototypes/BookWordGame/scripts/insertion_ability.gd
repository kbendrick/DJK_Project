class_name InsertionAbility
extends BookAbility


func _init() -> void:
	ability_id = &"insertion"
	display_name = "Insertion"
	description = "Choose a new letter, insert it at a selected cell, shift later letters down, and discard the last letter."
	action_point_cost = 1
	savvy_cost = 2
	insight_cost = 2
	required_targets = 1
	requires_letter_choice = true


func apply(model: LetterGridModel, targets: Array[Vector2i], letter_choice: String, _rng: RandomNumberGenerator) -> bool:
	return targets.size() == 1 and model.insert_at(targets[0], letter_choice)
