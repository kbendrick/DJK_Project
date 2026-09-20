class_name RotationAbility
extends BookAbility


func _init() -> void:
	ability_id = &"rotation"
	display_name = "Rotation"
	description = "Rotate all letters near selected letter clockwise"
	action_point_cost = 2
	savvy_cost = 2
	insight_cost = 0
	required_targets = 1


func apply(model: LetterGridModel, targets: Array[Vector2i], _letter_choice: String, _rng: RandomNumberGenerator) -> bool:
	return targets.size() == 1 and model.rotate(targets[0])
