class_name DeletionAbility
extends BookAbility


func _init() -> void:
	ability_id = &"deletion"
	display_name = "Deletion"
	description = "Remove one letter, shift every later letter up, and add a random letter at the end."
	action_point_cost = 1
	savvy_cost = 0
	insight_cost = 1
	required_targets = 1


func apply(model: LetterGridModel, targets: Array[Vector2i], _letter_choice: String, rng: RandomNumberGenerator) -> bool:
	return targets.size() == 1 and model.delete_at(targets[0], rng)
