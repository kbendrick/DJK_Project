extends CanvasLayer


signal finished(success: bool)

const MAX_BAR_WIDTH := 760.0
const MIN_BAR_WIDTH := 140.0
const PIXELS_PER_REQUIREMENT_POINT := 45.0
const CHUNK_ANIMATION_TIME := 2.5
const PURPLE_SKILL_ICON_SCALE := 2

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
@onready var requirement_1: Label = $Screen/Center/Panel/Margin/Layout/SkillIcon1/SkillRequirement1
@onready var requirement_2: Label = $Screen/Center/Panel/Margin/Layout/SkillIcon2/SkillRequirement2
var skill_icon_1_name: String
var skill_icon_2_name: String

var animated_sprite_array: Array[Dictionary]

var challenge_state: Dictionary
var assigned_companions: Array[Node] = []
var all_companions: Array[Node] = []
var random := RandomNumberGenerator.new()

var ball_time_scale: float = 1.0
var bar_width: float = MAX_BAR_WIDTH

var companion_displays: Array[AnimatedSprite2D] = []
var companion_skill_indicators: Array[Node2D] = []
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


func setup(
	new_challenge_state: Dictionary,
	new_assigned_companions: Array[Node],
	new_all_companions: Array[Node],
	_shelf_texture: Texture2D,
	_flip_shelf: bool
) -> void:
	# Set up the skill check with passsed in challenge states and assigned companions
	challenge_state = new_challenge_state.duplicate(true)
	assigned_companions = new_assigned_companions
	all_companions = new_all_companions

	# Creates an array with dictionaries for each skill check, displaying it for the player
	var skill_checks := _get_skill_checks()
	skill_icon_1.play(skill_checks[0]["name"])
	requirement_1.text = str(skill_checks[0]["requirement"])
	skill_icon_1_name = skill_checks[0]["name"]
	skill_icon_2.play(skill_checks[1]["name"])
	requirement_2.text = str(skill_checks[1]["requirement"])
	skill_icon_2_name = skill_checks[1]["name"]
	
	
	# Add animated sprites for the first two skill checks that display the sprite and check level
	animated_sprite_array.append({
		"name": skill_checks[0]["name"],
		"requirement": skill_checks[0]["requirement"],
		"sprite": skill_icon_1
	})
	
	animated_sprite_array.append({
		"name": skill_checks[1]["name"],
		"requirement": skill_checks[1]["requirement"],
		"sprite": skill_icon_2
	})
	
	_create_companion_displays()
	_create_requirement_indicator()
	_create_companion_skill_indicators()
	call_deferred("_run_skill_check")
	

func _create_companion_displays() -> void:
	# Remove old displays for characters
	for old_display in character_layer.get_children():
		old_display.queue_free()

	companion_displays.clear()

	var spacing := 130.0
	var first_x := -spacing * float(assigned_companions.size() - 1) / 2.0

	
	# For each assigned companion...
	for index in assigned_companions.size():
		# Find companion information, create an AnimatedSprite2D notes
		var companion = assigned_companions[index]
		var source_sprite: AnimatedSprite2D = companion.get_node("AnimatedSprite2D")
		var display_sprite := AnimatedSprite2D.new()

		# Display the sprite with all of the animation information loaded
		display_sprite.sprite_frames = source_sprite.sprite_frames
		display_sprite.animation = source_sprite.animation
		display_sprite.position = Vector2(first_x + index * spacing, 80)
		display_sprite.scale = Vector2(10, 10)
		display_sprite.play()

		# Add this display as a child to character_layer and the companion_displays array
		character_layer.add_child(display_sprite)
		companion_displays.append(display_sprite)


func _create_requirement_indicator() -> void:
	# Create a requirement indicator Node2D and add it to the bar_area
	requirement_indicator = Node2D.new()
	bar_area.add_child(requirement_indicator)

	# Add icons and animation to the requirement_indicator
	requirement_icon = AnimatedSprite2D.new()
	requirement_icon.sprite_frames = skill_icon_1.sprite_frames
	requirement_icon.scale = Vector2(1.5, 1.5)
	requirement_indicator.add_child(requirement_icon)

	# Add requirement number label to requirement_indicator
	requirement_number = Label.new()
	requirement_number.position = Vector2(22, -23)
	requirement_number.size = Vector2(70, 46)
	requirement_number.add_theme_font_size_override("font_size", 30)
	requirement_indicator.add_child(requirement_number)

	# Hide the requirement indicator once loaded
	requirement_indicator.hide()


func _create_companion_skill_indicators() -> void:
	# Clear all previous skill incicators/icons/numbers for companions
	companion_skill_indicators.clear()
	companion_skill_icons.clear()
	companion_skill_numbers.clear()

	# For each companion display...
	for display in companion_displays:
		# Create an incidator with an indicated position, add as a child to the character_layer, append to array
		var indicator := Node2D.new()
		indicator.position = Vector2(display.position.x, -40)
		character_layer.add_child(indicator)
		companion_skill_indicators.append(indicator)

		# Create an icon and add as a child to the indicator, append to array
		var icon := AnimatedSprite2D.new()
		icon.sprite_frames = skill_icon_1.sprite_frames
		icon.scale = Vector2(1.5, 1.5)
		indicator.add_child(icon)
		companion_skill_icons.append(icon)

		# Create a number label and add as a child to the indicator, append to array
		var number := Label.new()
		number.position = Vector2(22, -23)
		number.size = Vector2(70, 46)
		number.add_theme_font_size_override("font_size", 30)
		indicator.add_child(number)
		companion_skill_numbers.append(number)

		# Hide indicator
		indicator.hide()


func _run_skill_check() -> void:
	# Get array of dictionaries for each skill check
	var skill_checks := _get_skill_checks()

	# If there are no skill checks, give a label indicate that and exit function
	if skill_checks.is_empty():
		result_label.text = "No skills configured for this challenge."
		continue_button.show()
		continue_button.set_meta("success", false)
		return

	var total_requirement := 0
	var highest_requirement := 1

	# For each skill check in the array...
	for skill_check in skill_checks:
		# Set up a total reuqirement and highest requirement for the check
		var requirement: int = skill_check["requirement"]
		total_requirement += requirement
		highest_requirement = maxi(highest_requirement, requirement)

	# Set up skill check bar with a width clamped to the MIN_BAR_WIDTH and MAX_BAR_WIDTH
	bar_width = clampf(
		float(total_requirement) * PIXELS_PER_REQUIREMENT_POINT,
		MIN_BAR_WIDTH,
		MAX_BAR_WIDTH
	)

	# Create the title label for the bar
	title_label.text = challenge_state["name"].capitalize()
	black_bar.size.x = 0.0
	purple_fill.size.x = 0.0
	ball.hide()

	# Wait for requirement chunk animation to finish
	await _animate_requirement_chunks(skill_checks, total_requirement)

	# Get weighted total for the skill check
	var weighted_requirement_total := _get_weighted_requirement_total(
		skill_checks,
		highest_requirement
	)

	# Get total companion contributions (after the chunks are animated)
	var weighted_companion_total := await _animate_companion_chunks(
		skill_checks,
		highest_requirement,
		weighted_requirement_total
	)

	# Get the relative ratio of purple to black on the bar
	var purple_ratio := clampf(
		weighted_companion_total / maxf(1.0, weighted_requirement_total),
		0.0,
		1.0
	)

	# Get a label to display the result comparing the companion total to the requirement total
	result_label.text = "Weighted total: %.1f / %.1f" % [
		weighted_companion_total,
		weighted_requirement_total
	]

	# Show the ball for the upcoming check
	# The ball uses the actual variable width of this challenge's bar.
	ball.show()
	ball.pivot_offset = ball.size / 2.0
	ball.position.x = 0.0
	ball.scale = Vector2.ONE
	ball.rotation = 0.0
	ball.modulate = Color.WHITE

	# Makes sure the ball doesn't move past the edge of the bar
	var right_edge := bar_width - ball.size.x

	# Determines where the ball stops on the bar (in a ratio)
	var stop_ratio := random.randf()

	# wait for the ball to finish its fun animation
	await _animate_ball(right_edge, right_edge * stop_ratio)

	# Calculate the ball's ratio along the bar, check to see if it's in the pruple, and then call _resolve_result
	var ball_center_ratio := (ball.position.x + ball.size.x / 2.0) / bar_width
	var succeeded := ball_center_ratio <= purple_ratio
	_resolve_result(succeeded)


# This reads skill_1, skill_2, skill_3, and so on until the next numbered
# skill is absent. Adding another numbered skill therefore requires no change
# to the animation code.
func _get_skill_checks() -> Array[Dictionary]:
	var skill_checks: Array[Dictionary] = []
	var skill_number := 1

	# While loop that goes through every skill number until none are left
	while true:
		# Sets skill_key to skill_(1 - end of skills)
		var skill_key := "skill_" + str(skill_number)
		var requirement_key := skill_key + "_value"

		# If the challenge state doesn't have this skill_key, break the loop
		if not challenge_state.has(skill_key):
			break

		# If the challenge_state doesn't have the requirement, break the loop
		if not challenge_state.has(requirement_key):
			break

		# If the challenge_state dictionary doesn't have anything for the skill_key, break the loop
		if challenge_state[skill_key] == null:
			break

		# Set up skill_check as a dictionary with "name" for the type of skill and "requirement" for the challenge level
		var skill_check := {
			"name": str(challenge_state[skill_key]),
			"requirement": int(challenge_state[requirement_key])
		}

		# Append the skill_check to the skill_checks array and iterate
		skill_checks.append(skill_check)
		skill_number += 1

	# Returns skills checks as array of dictionaries
	return skill_checks


func _animate_requirement_chunks(skill_checks: Array[Dictionary], total_requirement: int) -> void:
	# Reset current_width of the bar
	var current_width := 0.0

	# For each skill_check
	for skill_check in skill_checks:
		# Get the information about the skill check
		var skill_name: String = skill_check["name"]
		var requirement: int = skill_check["requirement"]

		# Set up the chunk of the bar and adjust target_width
		var chunk_width := bar_width * float(requirement) / float(total_requirement)
		var target_width := current_width + chunk_width

		# Set up the icon, number, and indicator for the requirement, then show it
		requirement_icon.play(skill_name.to_lower())
		requirement_number.text = "0"
		requirement_indicator.position = Vector2(
			black_bar.position.x + current_width + 20.0,
			black_bar.position.y + black_bar.size.y / 2.0
		)
		requirement_indicator.show()
		
		# Print skill name and enlarge the icon on the bar
		print(skill_name)
		enlarge_skill_icon(skill_name, true)
		
		# Create a tween that animates the chunk width, x position, and number for this specific skill's portion
		var chunk_tween := create_tween()
		chunk_tween.set_parallel(true)
		chunk_tween.set_trans(Tween.TRANS_QUAD)
		chunk_tween.set_ease(Tween.EASE_OUT)
		# Animates black portion of the bar
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
		# Updates the number on the bar
		chunk_tween.tween_method(
			_update_number.bind(requirement_number, requirement),
			0.0,
			1.0,
			CHUNK_ANIMATION_TIME
		)
		await chunk_tween.finished
		
		# Once the chunk is finished, shrink it back to regular size
		enlarge_skill_icon(skill_name, false)
		
		# Set current width to the target width (that was animated into) and wait .15s
		current_width = target_width
		await get_tree().create_timer(0.15).timeout

	# Hide the requirement indicator now that animation is finished
	requirement_indicator.hide()

func _get_weighted_requirement_total(
	skill_checks: Array[Dictionary],
	highest_requirement: int
) -> float:
	# Reset the weighted total for a new check
	var weighted_total := 0.0

	for skill_check in skill_checks:
		# Get the integer assigned from the requirement and multiply it by a weight (requirement / highest requirement)
		var requirement: int = skill_check["requirement"]
		var weight := float(requirement) / float(highest_requirement)
		weighted_total += float(requirement) * weight

	return weighted_total


func _animate_companion_chunks(
	skill_checks: Array[Dictionary],
	highest_requirement: int,
	weighted_requirement_total: float
) -> float:
	# Reset weighted_companion_total for new check
	var weighted_companion_total := 0.0

	for skill_check in skill_checks:
		# Get skill_check name, requirement, weight (requirement/highest requirement)
		var skill_name: String = skill_check["name"]
		var requirement: int = skill_check["requirement"]
		var weight := float(requirement) / float(highest_requirement)
		var raw_skill_total := 0

		# For each companion assigned...
		for companion_index in assigned_companions.size():
			var companion := assigned_companions[companion_index]

			# Get the relevant stat from the companion and add it to the raw_skill_total
			var skill_value: int = companion.get_stat_value(skill_name)
			raw_skill_total += skill_value

			# Get the icon and number for the skill
			var icon := companion_skill_icons[companion_index]
			var number := companion_skill_numbers[companion_index]

			# Play the icon animation and set number to 0
			icon.play(skill_name.to_lower())
			number.text = "0"

			# Show the companion's skill indicators
			companion_skill_indicators[companion_index].show()

		# Changes the chunk based on the weight assigned, adds to weighted_companion_total
		var weighted_chunk := float(raw_skill_total) * weight
		weighted_companion_total += weighted_chunk

		# Changes the target for the purple bar width based on the new weight
		var purple_target := bar_width * clampf(
			weighted_companion_total / maxf(1.0, weighted_requirement_total),
			0.0,
			1.0
		)

		# This icon rides the leading edge of this skill's purple chunk.
		# It is not removed, so it remains at the chunk boundary afterward.
		var purple_start := purple_fill.size.x
		var bar_skill_icon: Array = _create_bar_skill_icon(skill_name,weight,purple_start)

		# Creates a tween that fulls up the black bar with purple based on the skills
		var fill_tween := create_tween()
		fill_tween.set_parallel(true)
		fill_tween.set_trans(Tween.TRANS_QUAD)
		fill_tween.set_ease(Tween.EASE_OUT)
		# Animates purple_fill of the bar
		fill_tween.tween_property(
			purple_fill,
			"size:x",
			purple_target,
			CHUNK_ANIMATION_TIME
		)
		# Animates the movement of the skill icon
		fill_tween.tween_property(
			bar_skill_icon[0],
			"position:x",
			black_bar.position.x + purple_target,
			CHUNK_ANIMATION_TIME
		)
		# Animates the other skill icon as well
		fill_tween.tween_property(
			bar_skill_icon[1],
			"position:x",
			black_bar.position.x + purple_target,
			CHUNK_ANIMATION_TIME
		)
		
		# Gather skill contributions from companions and animate the relative numbers
		for companion_index in assigned_companions.size():
			var companion := assigned_companions[companion_index]
			var skill_value: int = companion.get_stat_value(skill_name)
			var number := companion_skill_numbers[companion_index]

			# Animate the skill value update
			fill_tween.tween_method(
				_update_number.bind(number, skill_value),
				0.0,
				1.0,
				CHUNK_ANIMATION_TIME
			)

		await fill_tween.finished
		await get_tree().create_timer(0.15).timeout
	
	# For each assigned companion, hide their skill indicators
	for companion_index in assigned_companions.size():
		companion_skill_indicators[companion_index].hide()
	
	return weighted_companion_total


func _create_bar_skill_icon(
	skill_name: String,
	weight: float,
	purple_start: float
) -> Array:
	# Creates a skill icon
	var bar_skill_icon := AnimatedSprite2D.new()
	bar_skill_icon.sprite_frames = skill_icon_1.sprite_frames
	bar_skill_icon.play(skill_name.to_lower())
	bar_skill_icon.position = Vector2(
		black_bar.position.x + purple_start,
		black_bar.position.y + black_bar.size.y / 2.0
	)

	# Weight is between 0.0 and 1.0. The most important skill is the largest, with others smaller proportionally
	var icon_scale := PURPLE_SKILL_ICON_SCALE * weight
	bar_skill_icon.scale = Vector2(icon_scale, icon_scale)
	bar_skill_icon.z_index = 2
	bar_area.add_child(bar_skill_icon)
	
	# Adds a divider for the different icon chunks, adds it as a child to the bar_area
	var icon_divider := ColorRect.new()
	icon_divider.size = Vector2(5, black_bar.size.y - 4.0)
	icon_divider.position = Vector2(
		black_bar.position.x + purple_start,
		black_bar.position.y + 2.0
	)
	icon_divider.z_index = 1
	bar_area.add_child(icon_divider)

	# Create an array containing the bar_skill_icon and its divider and output
	var output_array: Array = [bar_skill_icon, icon_divider]	
	return output_array


func _update_number(progress: float, label: Label, target_value: int) -> void:
	label.text = str(roundi(float(target_value) * progress))


# Rapid wall-to-wall arcs create the high-energy portion of the roll.
func _animate_ball(right_edge: float, stop_x: float) -> void:
	# Set the ball's base position and how many times it will bounce off of the bar's sides
	var base_y := ball.position.y
	var bounce_count := 6

	for bounce_index in bounce_count:
		# Sets target_x to the right side on even bounce_index, otherwise left side
		var target_x := right_edge if bounce_index % 2 == 0 else 0.0

		# Keep track of the % of progress the ball has made (bounce progress, travel time)
		var bounce_progress := float(bounce_index) / float(maxi(1, bounce_count - 1))
		var travel_time := lerpf(0.16, 0.28, bounce_progress) * ball_time_scale

		# Determine how the ball hops vertically
		var hop_height := lerpf(10.0, 5.0, bounce_progress)
		var start_x := ball.position.x

		# Stretch ball scale (to show movement?)
		ball.scale = Vector2(1.22, 0.82)

		# Create a tween to move the ball between the ball
		var travel_tween := create_tween()
		travel_tween.set_parallel(true)
		# Moves ball in an arc between the two ends
		travel_tween.tween_method(
			_move_ball_arc.bind(start_x, target_x, base_y, hop_height),
			0.0,
			1.0,
			travel_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Animate rotation of the ball
		travel_tween.tween_property(
			ball,
			"rotation",
			ball.rotation + PI * (1.0 if target_x > start_x else -1.0),
			travel_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Animate scale of the ball
		travel_tween.tween_property(
			ball,
			"scale",
			Vector2.ONE,
			travel_time
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await travel_tween.finished

		# Set the ball's position to the target_x and the standard y
		ball.position = Vector2(target_x, base_y)
		await _play_ball_impact()
		ball_time_scale += 0.2

	# After bounces are done, set ball back to its "movement" scale
	ball.scale = Vector2(1.16, 0.86)

	# Create a final tween to move the ball to its final destination
	var final_tween := create_tween()
	final_tween.set_parallel(true)
	# Animate X position
	final_tween.tween_property(
		ball,
		"position:x",
		stop_x,
		2.0 * ball_time_scale
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Animate ball rotation
	final_tween.tween_property(
		ball,
		"rotation",
		roundf(ball.rotation / TAU) * TAU,
		1.7 * ball_time_scale
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Animate ball scale
	final_tween.tween_property(
		ball,
		"scale",
		Vector2.ONE,
		0.06 * ball_time_scale
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await final_tween.finished

	# Set the ball's position and play a final pulse animation
	ball.position = Vector2(stop_x, base_y)
	await _play_final_pulse()


# Function to affect ball's Y position based on its progress along the bar
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


# A couple of animations to make it look like the ball "squishes" up against the side of the bar
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


# Create a tween that generates a ball "pulse" to indicate to the player that things are finished
func _play_final_pulse() -> void:
	var pulse_tween := create_tween()
	# Increase ball scale
	pulse_tween.tween_property(
		ball,
		"scale",
		Vector2(1.35, 1.35),
		0.10
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Change the ball's color
	pulse_tween.parallel().tween_property(
		ball,
		"modulate",
		Color(0.78, 0.48, 1.0, 1.0),
		0.10
	)
	# Decrease ball scale
	pulse_tween.tween_property(
		ball,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	pulse_tween.parallel().tween_property(ball, "modulate", Color.WHITE, 0.18)
	await pulse_tween.finished


# Function to show success/failure label and add a continue button
func _resolve_result(succeeded: bool) -> void:
	if succeeded:
		result_label.text = "SUCCESS"

		for index in assigned_companions.size():
			var companion = assigned_companions[index]
			var display = companion_displays[index]
			#display.play(companion.companion_name.to_lower() + "_success")
	else:
		result_label.text = "FAILURE"

		for index in assigned_companions.size():
			var companion = assigned_companions[index]
			var display = companion_displays[index]
			#display.play(companion.companion_name.to_lower() + "_hurt")

	# Rewards and penalties are intentionally not applied here. They are
	# applied by the point of interest after this scene closes.
	continue_button.show()
	continue_button.set_meta("success", succeeded)


# Find the skill sprite based on the passed in name and enlarge it; shrink everything else
func enlarge_skill_icon(skill_name: String, enlarge: bool) -> void:
	for sprites in animated_sprite_array:
		if sprites["name"] == skill_name:
			if enlarge:
				sprites["sprite"].scale = Vector2(2.5, 2.5)
				print(sprites["name"] + " enlarge")
				break
			else:
				sprites["sprite"].scale = Vector2(1.5, 1.5)
				print(sprites["name"] + " shrink")
				break

# If continue button is pressed, close window
func _close() -> void:
	var succeeded: bool = continue_button.get_meta("success", false)
	finished.emit(succeeded)
	queue_free()
