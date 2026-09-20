class_name SubstitutionAbility
extends BookAbility


func _init() -> void:
	ability_id = &"substitution"
	display_name = "Substitution"
	description = "Replace one selected letter with a different random letter."
	action_point_cost = 1
	savvy_cost = 1
	insight_cost = 1
	required_targets = 1

# If a cell is selected and substitute() works, return true
func apply(model: LetterGridModel, targets: Array[Vector2i], _letter_choice: String, rng: RandomNumberGenerator) -> bool:
	return targets.size() == 1 and model.substitute(targets[0], rng)
