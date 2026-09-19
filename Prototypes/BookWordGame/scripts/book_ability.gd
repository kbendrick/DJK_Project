class_name BookAbility
extends Resource

@export var ability_id: StringName = &"ability"
@export var display_name := "Ability"
@export_multiline var description := ""
@export_range(0, 20) var action_point_cost := 1
@export_range(0, 20) var savvy_cost := 0
@export_range(0, 20) var insight_cost := 0
@export_range(1, 4) var required_targets := 1
@export var requires_letter_choice := false


func is_valid_next_target(_model: LetterGridModel, current_targets: Array[Vector2i], cell: Vector2i) -> bool:
	return not current_targets.has(cell)


func apply(_model: LetterGridModel, _targets: Array[Vector2i], _letter_choice: String, _rng: RandomNumberGenerator) -> bool:
	return false
