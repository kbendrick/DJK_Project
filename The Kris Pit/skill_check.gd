extends CanvasLayer


signal finished(success: bool)

const BAR_WIDTH := 760.0

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

	# Stage 3: bounce the ball repeatedly, then stop at a random position.
	ball.show()
	ball.position.x = 0.0
	var right_edge := BAR_WIDTH - ball.size.x
	var ball_tween := create_tween()
	ball_tween.set_trans(Tween.TRANS_SINE)
	ball_tween.set_ease(Tween.EASE_IN_OUT)

	for bounce_index in 6:
		var target_x := right_edge if bounce_index % 2 == 0 else 0.0
		ball_tween.tween_property(ball,"position:x",target_x,0.20 + (bounce_index*5) * 0.06)

	var stop_ratio := random.randf()
	ball_tween.tween_property(ball, "position:x", right_edge * stop_ratio, 5)
	await ball_tween.finished

	var ball_center_ratio := (ball.position.x + ball.size.x / 2.0) / BAR_WIDTH
	var succeeded := ball_center_ratio <= purple_ratio
	_resolve_result(succeeded)


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
