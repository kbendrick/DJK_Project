extends CanvasLayer


signal finished(success: bool)

const MAX_BAR_WIDTH := 760.0
const MIN_BAR_WIDTH := 140.0
const PIXELS_PER_REQUIREMENT_POINT := 45.0
const CHUNK_ANIMATION_TIME := 0.8

@onready var title_label: Label = $Screen/Center/Panel/Margin/Layout/Title
@onready var character_layer: Node2D = $Screen/Center/Panel/Margin/Layout/Stage/CharacterLayer
@onready var bar_area: Control = $Screen/Center/Panel/Margin/Layout/BarArea
@onready var black_bar: Panel = $Screen/Center/Panel/Margin/Layout/BarArea/BlackBar
@onready var purple_fill: ColorRect = $Screen/Center/Panel/Margin/Layout/BarArea/BlackBar/PurpleFill
@onready var ball: Panel = $Screen/Center/Panel/Margin/Layout/BarArea/BlackBar/Ball
@onready var result_label: Label = $Screen/Center/Panel/Margin/Layout/ResultLabel
@onready var continue_button: Button = $Screen/Center/Panel/Margin/Layout/ContinueButton

# These scene icons provide the SpriteFrames shared by all five skills.
# The animated indicators used during the check are created below in code.
@onready var skill_icon_1: AnimatedSprite2D = $Screen/Center/Panel/Margin/Layout/SkillIcon1
@onready var skill_icon_2: AnimatedSprite2D = $Screen/Center/Panel/Margin/Layout/SkillIcon2

var challenge_state: Dictionary
var assigned_companions: Array[Node] = []
var all_companions: Array[Node] = []
var random := RandomNumberGenerator.new()

var ball_time_scale: float = 1.0
var bar_width: float = MAX_BAR_WIDTH

var companion_displays: Array[AnimatedSprite2D] = []
var companion_skill_icons: Array[AnimatedSprite2D] = []
var companion_skill_numbers: Array[Label] = []

var requirement_indicator: Node2D
var requirement_icon: AnimatedSprite2D
var requirement_number: Label


func _ready() -> void:
	random.randomize()
	continue_button.pressed.connect(_close)
	continue_button.hide()
	ball.hide()
	result_label.text = ""

	# The original fixed icons are replaced by indicators that can support
	# any number of required skills.
	skill_icon_1.hide()
	skill_icon_2.hide()


func setup(
	new_challenge_state: Dictionary,
	new_assigned_companions: Array[Node],
	new_all_companions: Array[Node],
	_shelf_texture: Texture2D,
	_flip_shelf: bool
) -> void:
	challenge_state = new_challenge_state.duplicate(true)
	assigned_companions = new_assigned_companions
	all_companions = new_all_companions

	_create_companion_displays()
	_create_requirement_indicator()
	_create_companion_skill_indicators()
	call_deferred("_run_skill_check")


func _create_companion_displays() -> void:
	for old_display in character_layer.get_children():
		old_display.queue_free()

	companion_displays.clear()

	var spacing := 130.0
	var first_x := -spacing * float(assigned_companions.size() - 1) / 2.0

	for index in assigned_companions.size():
		var companion = assigned_companions[index]
		var source_sprite: AnimatedSprite2D = companion.get_node("AnimatedSprite2D")
		var display_sprite := AnimatedSprite2D.new()

		display_sprite.sprite_frames = source_sprite.sprite_frames
		display_sprite.animation = source_sprite.animation
		display_sprite.position = Vector2(first_x + index * spacing, 80)
		display_sprite.scale = Vector2(10, 10)
		display_sprite.play()
		character_layer.add_child(display_sprite)
		companion_displays.append(display_sprite)


func _create_requirement_indicator() -> void:
	requirement_indicator = Node2D.new()
	bar_area.add_child(requirement_indicator)

	requirement_icon = AnimatedSprite2D.new()
	requirement_icon.sprite_frames = skill_icon_1.sprite_frames
	requirement_icon.scale = Vector2(1.5, 1.5)
	requirement_indicator.add_child(requirement_icon)

	requirement_number = Label.new()
	requirement_number.position = Vector2(22, -23)
	requirement_number.size = Vector2(70, 46)
	requirement_number.add_theme_font_size_override("font_size", 30)
	requirement_indicator.add_child(requirement_number)


func _create_companion_skill_indicators() -> void:
	companion_skill_icons.clear()
	companion_skill_numbers.clear()

	for display in companion_displays:
		var indicator := Node2D.new()
		indicator.position = Vector2(display.position.x, -40)
		character_layer.add_child(indicator)

		var icon := AnimatedSprite2D.new()
		icon.sprite_frames = skill_icon_1.sprite_frames
		icon.scale = Vector2(1.5, 1.5)
		indicator.add_child(icon)
		companion_skill_icons.append(icon)

		var number := Label.new()
		number.position = Vector2(22, -23)
		number.size = Vector2(70, 46)
		number.add_theme_font_size_override("font_size", 30)
		indicator.add_child(number)
		companion_skill_numbers.append(number)

		indicator.hide()


func _run_skill_check() -> void:
	var skill_checks := _get_skill_checks()

	if skill_checks.is_empty():
		result_label.text = "No skills configured for this challenge."
		continue_button.show()
		continue_button.set_meta("success", false)
		return

	var total_requirement := 0
	var highest_requirement := 1

	for skill_check in skill_checks:
		var requirement: int = skill_check["requirement"]
		total_requirement += requirement
		highest_requirement = maxi(highest_requirement, requirement)

	bar_width = clampf(
		float(total_requirement) * PIXELS_PER_REQUIREMENT_POINT,
		MIN_BAR_WIDTH,
		MAX_BAR_WIDTH
	)

	title_label.text = challenge_state["name"].capitalize() + " Challenge"
	black_bar.size.x = 0.0
	purple_fill.size.x = 0.0
	ball.hide()

	await _animate_requirement_chunks(skill_checks, total_requirement)

	var weighted_requirement_total := _get_weighted_requirement_total(
		skill_checks,
		highest_requirement
	)

	var weighted_companion_total := await _animate_companion_chunks(
		skill_checks,
		highest_requirement,
		weighted_requirement_total
	)

	var purple_ratio := clampf(
		weighted_companion_total / maxf(1.0, weighted_requirement_total),
		0.0,
		1.0
	)

	result_label.text = "Weighted total: %.1f / %.1f" % [
		weighted_companion_total,
		weighted_requirement_total
	]

	# The ball uses the actual variable width of this challenge's bar.
	ball.show()
	ball.pivot_offset = ball.size / 2.0
	ball.position.x = 0.0
	ball.scale = Vector2.ONE
	ball.rotation = 0.0
	ball.modulate = Color.WHITE

	var right_edge := bar_width - ball.size.x
	var stop_ratio := random.randf()
	await _animate_ball(right_edge, right_edge * stop_ratio)

	var ball_center_ratio := (ball.position.x + ball.size.x / 2.0) / bar_width
	var succeeded := ball_center_ratio <= purple_ratio
	_resolve_result(succeeded)


# This reads skill_1, skill_2, skill_3, and so on until the next numbered
# skill is absent. Adding another numbered skill therefore requires no change
# to the animation code.
func _get_skill_checks() -> Array[Dictionary]:
	var skill_checks: Array[Dictionary] = []
	var skill_number := 1

	while true:
		var skill_key := "skill_" + str(skill_number)
		var requirement_key := skill_key + "_value"

		if not challenge_state.has(skill_key):
			break

		if not challenge_state.has(requirement_key):
			break

		if challenge_state[skill_key] == null:
			break

		var skill_check := {
			"name": str(challenge_state[skill_key]),
			"requirement": int(challenge_state[requirement_key])
		}

		skill_checks.append(skill_check)
		skill_number += 1

	return skill_checks


func _animate_requirement_chunks(
	skill_checks: Array[Dictionary],
	total_requirement: int
) -> void:
	var current_width := 0.0

	for skill_check in skill_checks:
		var skill_name: String = skill_check["name"]
		var requirement: int = skill_check["requirement"]
		var chunk_width := bar_width * float(requirement) / float(total_requirement)
		var target_width := current_width + chunk_width

		requirement_icon.play(skill_name.to_lower())
		requirement_number.text = "0"
		requirement_indicator.position = Vector2(
			black_bar.position.x + current_width + 20.0,
			black_bar.position.y + 25.0
		)
		requirement_indicator.show()

		var chunk_tween := create_tween()
		chunk_tween.set_parallel(true)
		chunk_tween.set_trans(Tween.TRANS_QUAD)
		chunk_tween.set_ease(Tween.EASE_OUT)
		chunk_tween.tween_property(
			black_bar,
			"size:x",
			target_width,
			CHUNK_ANIMATION_TIME
		)
		chunk_tween.tween_property(
			requirement_indicator,
			"position:x",
			black_bar.position.x + target_width + 20.0,
			CHUNK_ANIMATION_TIME
		)
		chunk_tween.tween_method(
			_update_number.bind(requirement_number, requirement),
			0.0,
			1.0,
			CHUNK_ANIMATION_TIME
		)
		await chunk_tween.finished

		current_width = target_width
		await get_tree().create_timer(0.15).timeout


func _get_weighted_requirement_total(
	skill_checks: Array[Dictionary],
	highest_requirement: int
) -> float:
	var weighted_total := 0.0

	for skill_check in skill_checks:
		var requirement: int = skill_check["requirement"]
		var weight := float(requirement) / float(highest_requirement)
		weighted_total += float(requirement) * weight

	return weighted_total


func _animate_companion_chunks(
	skill_checks: Array[Dictionary],
	highest_requirement: int,
	weighted_requirement_total: float
) -> float:
	var weighted_companion_total := 0.0

	for skill_check in skill_checks:
		var skill_name: String = skill_check["name"]
		var requirement: int = skill_check["requirement"]
		var weight := float(requirement) / float(highest_requirement)
		var raw_skill_total := 0

		for companion_index in assigned_companions.size():
			var companion := assigned_companions[companion_index]
			var skill_value: int = companion.get_stat_value(skill_name)
			raw_skill_total += skill_value

			var icon := companion_skill_icons[companion_index]
			var number := companion_skill_numbers[companion_index]
			icon.play(skill_name.to_lower())
			number.text = "0"
			icon.get_parent().show()

		var weighted_chunk := float(raw_skill_total) * weight
		weighted_companion_total += weighted_chunk

		var purple_target := bar_width * clampf(
			weighted_companion_total / maxf(1.0, weighted_requirement_total),
			0.0,
			1.0
		)

		var fill_tween := create_tween()
		fill_tween.set_parallel(true)
		fill_tween.set_trans(Tween.TRANS_QUAD)
		fill_tween.set_ease(Tween.EASE_OUT)
		fill_tween.tween_property(
			purple_fill,
			"size:x",
			purple_target,
			CHUNK_ANIMATION_TIME
		)

		for companion_index in assigned_companions.size():
			var companion := assigned_companions[companion_index]
			var skill_value: int = companion.get_stat_value(skill_name)
			var number := companion_skill_numbers[companion_index]

			fill_tween.tween_method(
				_update_number.bind(number, skill_value),
				0.0,
				1.0,
				CHUNK_ANIMATION_TIME
			)

		await fill_tween.finished
		await get_tree().create_timer(0.15).timeout

	return weighted_companion_total


func _update_number(progress: float, label: Label, target_value: int) -> void:
	label.text = str(roundi(float(target_value) * progress))


# Rapid wall-to-wall arcs create the high-energy portion of the roll.
func _animate_ball(right_edge: float, stop_x: float) -> void:
	var base_y := ball.position.y
	var bounce_count := 6

	for bounce_index in bounce_count:
		var target_x := right_edge if bounce_index % 2 == 0 else 0.0
		var bounce_progress := float(bounce_index) / float(maxi(1, bounce_count - 1))
		var travel_time := lerpf(0.16, 0.28, bounce_progress) * ball_time_scale
		var hop_height := lerpf(10.0, 5.0, bounce_progress)
		var start_x := ball.position.x

		ball.scale = Vector2(1.22, 0.82)
		var travel_tween := create_tween()
		travel_tween.set_parallel(true)
		travel_tween.tween_method(
			_move_ball_arc.bind(start_x, target_x, base_y, hop_height),
			0.0,
			1.0,
			travel_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		travel_tween.tween_property(
			ball,
			"rotation",
			ball.rotation + PI * (1.0 if target_x > start_x else -1.0),
			travel_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		travel_tween.tween_property(
			ball,
			"scale",
			Vector2.ONE,
			travel_time
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await travel_tween.finished

		ball.position = Vector2(target_x, base_y)
		await _play_ball_impact()
		ball_time_scale += 0.2

	ball.scale = Vector2(1.16, 0.86)
	var final_tween := create_tween()
	final_tween.set_parallel(true)
	final_tween.tween_property(
		ball,
		"position:x",
		stop_x,
		2.0 * ball_time_scale
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	final_tween.tween_property(
		ball,
		"rotation",
		roundf(ball.rotation / TAU) * TAU,
		1.7 * ball_time_scale
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	final_tween.tween_property(
		ball,
		"scale",
		Vector2.ONE,
		0.06 * ball_time_scale
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await final_tween.finished

	ball.position = Vector2(stop_x, base_y)
	await _play_final_pulse()


func _move_ball_arc(
	progress: float,
	start_x: float,
	end_x: float,
	base_y: float,
	hop_height: float
) -> void:
	var horizontal_progress := (1.0 - cos(progress * PI)) / 2.0
	ball.position.x = lerpf(start_x, end_x, horizontal_progress)
	ball.position.y = base_y - sin(progress * PI) * hop_height


func _play_ball_impact() -> void:
	var squash_tween := create_tween()
	squash_tween.set_parallel(true)
	squash_tween.tween_property(
		ball,
		"scale",
		Vector2(0.72, 1.30),
		0.055
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(
		ball,
		"modulate",
		Color(0.92, 0.65, 1.0, 1.0),
		0.055
	)
	await squash_tween.finished

	var recover_tween := create_tween()
	recover_tween.set_parallel(true)
	recover_tween.tween_property(
		ball,
		"scale",
		Vector2.ONE,
		0.075
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recover_tween.tween_property(ball, "modulate", Color.WHITE, 0.075)
	await recover_tween.finished


func _play_final_pulse() -> void:
	var pulse_tween := create_tween()
	pulse_tween.tween_property(
		ball,
		"scale",
		Vector2(1.35, 1.35),
		0.10
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse_tween.parallel().tween_property(
		ball,
		"modulate",
		Color(0.78, 0.48, 1.0, 1.0),
		0.10
	)
	pulse_tween.tween_property(
		ball,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	pulse_tween.parallel().tween_property(ball, "modulate", Color.WHITE, 0.18)
	await pulse_tween.finished


func _resolve_result(succeeded: bool) -> void:
	if succeeded:
		result_label.text = "SUCCESS"

		for index in assigned_companions.size():
			var companion = assigned_companions[index]
			var display = companion_displays[index]
			display.play(companion.companion_name.to_lower() + "_success")
	else:
		result_label.text = "FAILURE"

		for index in assigned_companions.size():
			var companion = assigned_companions[index]
			var display = companion_displays[index]
			display.play(companion.companion_name.to_lower() + "_hurt")

	# Rewards and penalties are intentionally not applied here. They are
	# applied by the point of interest after this scene closes.
	continue_button.show()
	continue_button.set_meta("success", succeeded)


func _close() -> void:
	var succeeded: bool = continue_button.get_meta("success", false)
	finished.emit(succeeded)
	queue_free()
