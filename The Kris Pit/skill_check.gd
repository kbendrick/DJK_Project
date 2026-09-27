extends CanvasLayer


signal finished(success: bool)

const BAR_WIDTH := 760.0

# Ball motion tuning. The settle curve keeps the early rebounds wide and
# pulls the final rebounds sharply toward the chosen result.
const BALL_BOUNCE_COUNT := 6
const BALL_SETTLE_CURVE := 2.4
const BALL_FINAL_DISTANCE := 0.08
const BALL_BOUNCE_VARIATION := 0.10
const BALL_FIRST_TRAVEL_TIME := 0.18
const BALL_LAST_TRAVEL_TIME := 0.70
const BALL_FINAL_APPROACH_TIME := 1.8

@onready var title_label: Label = $Screen/Center/Panel/Margin/Layout/Title
@onready var skill_label: Label = $Screen/Center/Panel/Margin/Layout/SkillLabel
@onready var requirement_label: Label = $Screen/Center/Panel/Margin/Layout/RequirementLabel
#@onready var bookshelf: Sprite2D = $Screen/Center/Panel/Margin/Layout/Stage/Bookshelf
@onready var character_layer: Node2D = $Screen/Center/Panel/Margin/Layout/Stage/CharacterLayer
@onready var black_bar: Panel = $Screen/Center/Panel/Margin/Layout/BarArea/BlackBar
@onready var purple_fill: ColorRect = $Screen/Center/Panel/Margin/Layout/BarArea/BlackBar/PurpleFill
@onready var ball: Panel = $Screen/Center/Panel/Margin/Layout/BarArea/BlackBar/Ball
@onready var result_label: Label = $Screen/Center/Panel/Margin/Layout/ResultLabel
@onready var continue_button: Button = $Screen/Center/Panel/Margin/Layout/ContinueButton

var challenge_state: Dictionary
var assigned_companions: Array[Node] = []
var all_companions: Array[Node] = []
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.randomize()
	continue_button.pressed.connect(_close)
	continue_button.hide()
	ball.hide()
	result_label.text = ""


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
	call_deferred("_run_skill_check")


func _create_companion_displays() -> void:
	for old_display in character_layer.get_children():
		old_display.queue_free()

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


func _run_skill_check() -> void:
	var skill_1: String = challenge_state["skill_1"]
	var skill_2: String = challenge_state["skill_2"]
	var requirement_1: int = challenge_state["skill_1_value"]
	var requirement_2: int = challenge_state["skill_2_value"]
	var total_requirement := requirement_1 + requirement_2
	var companion_total := _get_companion_skill_total(skill_1, skill_2)
	var purple_ratio := clampf(
		float(companion_total) / float(maxi(1, total_requirement)),
		0.0,
		1.0
	)

	title_label.text = challenge_state["name"].capitalize() + " Challenge"
	skill_label.text = "%s + %s" % [skill_1.capitalize(), skill_2.capitalize()]

	black_bar.size.x = 0.0
	purple_fill.size.x = 0.0
	requirement_label.text = "Requirements: %s 0/%d   •   %s 0/%d" % [
		skill_1.capitalize(), requirement_1,
		skill_2.capitalize(), requirement_2
	]

	# Stage 1: reveal how long the black difficulty bar is.
	var requirement_tween := create_tween()
	requirement_tween.set_parallel(true)
	requirement_tween.set_trans(Tween.TRANS_QUAD)
	requirement_tween.set_ease(Tween.EASE_OUT)
	requirement_tween.tween_property(black_bar, "size:x", BAR_WIDTH, 1.4)
	requirement_tween.tween_method(
		_update_requirement_count.bind(
			skill_1,
			requirement_1,
			skill_2,
			requirement_2
		),
		0.0,
		1.0,
		1.4
	)
	await requirement_tween.finished

	# Stage 2: fill the amount covered by the companions in purple.
	result_label.text = "Companion total: %d" % companion_total
	var fill_tween := create_tween()
	fill_tween.set_trans(Tween.TRANS_QUAD)
	fill_tween.set_ease(Tween.EASE_OUT)
	fill_tween.tween_property(
		purple_fill,
		"size:x",
		BAR_WIDTH * purple_ratio,
		1.2
	)
	await fill_tween.finished

	# Stage 3: energetic rebounds followed by a long, slow final approach.
	ball.show()
	ball.pivot_offset = ball.size / 2.0
	ball.position.x = 0.0
	ball.scale = Vector2.ONE
	ball.rotation = 0.0
	ball.modulate = Color.WHITE

	var right_edge := BAR_WIDTH - ball.size.x
	var stop_ratio := random.randf()
	await _animate_ball(right_edge, right_edge * stop_ratio)

	var ball_center_ratio := (ball.position.x + ball.size.x / 2.0) / BAR_WIDTH
	var succeeded := ball_center_ratio <= purple_ratio
	_resolve_result(succeeded)


# Six alternating arcs form a damped oscillation around stop_x.
# The result is already fixed; only the displayed motion converges toward it.
func _animate_ball(right_edge: float, stop_x: float) -> void:
	var base_y := ball.position.y

	for bounce_index in BALL_BOUNCE_COUNT:
		var bounce_progress := (
			float(bounce_index)
			/ float(maxi(1, BALL_BOUNCE_COUNT - 1))
		)

		# Raising progress to a power greater than 1 creates an ease-in curve:
		# early bounces remain wide, then the final bounces close in quickly.
		var settle_progress := pow(bounce_progress, BALL_SETTLE_CURVE)
		var distance_from_result := lerpf(
			1.0,
			BALL_FINAL_DISTANCE,
			settle_progress
		)

		# Slightly vary each intermediate amplitude so players cannot reliably
		# find stop_x by averaging the left and right endpoints.
		var variation := random.randf_range(
			1.0 - BALL_BOUNCE_VARIATION,
			1.0 + BALL_BOUNCE_VARIATION
		)
		distance_from_result = clampf(
			distance_from_result * variation,
			BALL_FINAL_DISTANCE,
			1.0
		)

		var edge_target := right_edge if bounce_index % 2 == 0 else 0.0
		var target_x := lerpf(stop_x, edge_target, distance_from_result)

		# Later bounces travel a shorter distance but take longer, so the ball
		# visibly loses energy as it settles around its predetermined result.
		var travel_time := lerpf(
			BALL_FIRST_TRAVEL_TIME,
			BALL_LAST_TRAVEL_TIME,
			bounce_progress
		)
		var hop_height := lerpf(10.0, 3.0, bounce_progress)
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

	# The six bounces finish close to stop_x. This last tween completes the
	# predetermined result with a slow exponential settle.
	ball.scale = Vector2(1.10, 0.90)
	var final_tween := create_tween()
	final_tween.set_parallel(true)
	final_tween.tween_property(
		ball,
		"position:x",
		stop_x,
		BALL_FINAL_APPROACH_TIME
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	final_tween.tween_property(
		ball,
		"rotation",
		roundf(ball.rotation / TAU) * TAU,
		BALL_FINAL_APPROACH_TIME
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	final_tween.tween_property(
		ball,
		"scale",
		Vector2.ONE,
		BALL_FINAL_APPROACH_TIME
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
	# The sine curve is zero at both ends and tallest in the middle.
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


func _update_requirement_count(
	progress: float,
	skill_1: String,
	requirement_1: int,
	skill_2: String,
	requirement_2: int
) -> void:
	var shown_1 := roundi(requirement_1 * progress)
	var shown_2 := roundi(requirement_2 * progress)

	requirement_label.text = "Requirements: %s %d/%d   •   %s %d/%d" % [
		skill_1.capitalize(), shown_1, requirement_1,
		skill_2.capitalize(), shown_2, requirement_2
	]


func _get_companion_skill_total(skill_1: String, skill_2: String) -> int:
	var total := 0

	for companion in assigned_companions:
		total += companion.get_stat_value(skill_1)
		total += companion.get_stat_value(skill_2)

	return total


func _resolve_result(succeeded: bool) -> void:
	if succeeded:
		result_label.text = "SUCCESS"
		var i = 0
		for companion in assigned_companions:
			character_layer.get_child(i).play(companion.companion_name.to_lower() + "_success")
			i += 1
		if challenge_state["name"] == "hazard":
			print("Hazard succeeded. Nothing happens.")
		else:
			print(
				"Challenge reward: ",
				challenge_state["reward_amount"],
				" ",
				challenge_state["reward"]
			)
	else:
		result_label.text = "FAILURE"

		if challenge_state["name"] == "hazard":
			_apply_hazard_failure()
		else:
			var i = 0
			for companion in assigned_companions:
				companion.lose_sanity(1)
				character_layer.get_child(i).play(companion.companion_name.to_lower() + "_hurt")
				i += 1
			print("Challenge failed. Assigned companions lose 1 sanity.")

	continue_button.show()
	continue_button.set_meta("success", succeeded)


func _apply_hazard_failure() -> void:
	var penalty_amount: int = challenge_state["reward_amount"]

	if challenge_state["reward"] == "steps":
		global.steps = maxi(0, global.steps - penalty_amount)
		print("Hazard failed. Lost ", penalty_amount, " steps. Steps remaining: ", global.steps)
	else:
		for companion in all_companions:
			companion.lose_sanity(1)
		print("Hazard failed. Every companion loses ", 1, " sanity.")


func _close() -> void:
	var succeeded: bool = continue_button.get_meta("success", false)
	finished.emit(succeeded)
	queue_free()
