extends Node2D


const SKILL_CHECK_SCENE := preload("res://The Kris Pit/skill_check.tscn")

enum shelf_types {FrontShelf, SideShelf}

@export var interactable_square: PackedScene
@export var shelf_type: shelf_types = shelf_types.FrontShelf
@export var Flip_H: bool = false

@onready var FrontShelf: Sprite2D = $FrontShelf
@onready var SideShelf: Sprite2D = $SideShelf
@onready var POI_Icon: AnimatedSprite2D = $POI_Icon
@onready var interact1: Marker2D = $InteractableMarker1
@onready var interact2: Marker2D = $InteractableMarker2
@onready var interact3: Marker2D = $InteractableMarker3
@onready var skill_icon_1: AnimatedSprite2D = $POI_Icon/PanelContainer/SkillIcon1
@onready var skill_icon_2: AnimatedSprite2D = $POI_Icon/PanelContainer/SkillIcon2
@onready var shelf_type_icon: AnimatedSprite2D = $POI_Icon
@onready var interact_click_area: Area2D = $POI_Icon/InteractClickArea

var interactables: Array = []
var is_hovered := false
var is_ready := false
var is_resolved := false
var skill_check_open := false

var rng := RandomNumberGenerator.new()
var possible_states: Array[String] = ["hazard", "currency", "heal", "mystery", "rest", "upgrade"]
var current_state: Dictionary = {
	"name": null,
	"reward": null,
	"reward_amount": null,
	"skill_1": null,
	"skill_1_value": null,
	"skill_2": null,
	"skill_2_value": null,
	"difficulty_level": null
}


func _ready() -> void:
	rng.randomize()

	var current_scene_root := get_tree().current_scene

	# Finds the button in the current scene, if there is one
	var button := _find_button_recursive(current_scene_root)

	if button:
		button.pressed.connect(_on_button_pressed)

	interact_click_area.mouse_entered.connect(_on_mouse_entered)
	interact_click_area.mouse_exited.connect(_on_mouse_exited)

	# Sets shelf layout and the random challenges that take place within
	_set_shelf_layout()
	_create_random_challenge()


# If the mouse is hovering over the shelf, it's ready to open, and the skill check isn't open, open it on left click
func _process(_delta: float) -> void:
	if is_hovered and is_ready and not skill_check_open:
		if Input.is_action_just_pressed("left_click"):
			_open_skill_check()


# Reorients the shelf and adds interaction points based on its layout in the room
func _set_shelf_layout() -> void:
	match shelf_type:
		shelf_types.FrontShelf:
			FrontShelf.visible = true
			SideShelf.visible = false
			POI_Icon.position = Vector2(0, -49)
			interact1.position = Vector2(-48, 14)
			interact2.position = Vector2(0, 14)
			interact3.position = Vector2(48, 14)

		shelf_types.SideShelf:
			FrontShelf.visible = false
			SideShelf.visible = true
			SideShelf.flip_h = Flip_H

			var flip_multi := -1 if Flip_H else 1
			interact1.position = Vector2(33 * flip_multi, -9)
			interact2.position = Vector2(33 * flip_multi, -44)
			interact3.position = Vector2(33 * flip_multi, -79)


func _create_random_challenge() -> void:
	# Chooses a random key from the possible states and then *currently 2* additional options
	var database_key := possible_states[rng.randi_range(0, possible_states.size() - 1)]
	database_key += "_" + str(rng.randi_range(1, 2))
	var selected_poi_database: Dictionary = POI_database.poi_dict[database_key]

	# For each of the keys in the dictionary for the database_key, copy it into current_state
	for key in selected_poi_database:
		current_state[key] = selected_poi_database[key]

	# Set a hazard skill index with the randomizer
	var hazard_skill_index := rng.randi_range(0, 4)
	var combined_skill_values := 0
	var skill_number := 1

	# Numbered skills make the challenge expandable. Adding skill_3 or
	# skill_4 to the database also gives that skill a requirement here.
	# Iterates through skill numbers until it isn't found in the poi_dict dictionary
	while true:
		# Set skill_key and requirement_key using the skill_number variable
		var skill_key := "skill_" + str(skill_number)
		var requirement_key := skill_key + "_value"

		# If skill_key is not found in the current_state dictionary, exit function
		if not current_state.has(skill_key):
			break

		# If skill_key is null in the current_state dictionary, exit function
		if current_state[skill_key] == null:
			break

		# Hazards have arrays in the [skill_key]; this if checks for this and uses hazard_skill_index to pull from array
		if current_state[skill_key] is Array:
			current_state[skill_key] = current_state[skill_key][hazard_skill_index]

		# Randomizes the requirement between 2 and 8, sets the requirement key and adds number to combined_skill_values
		var requirement := rng.randi_range(2, 8)
		current_state[requirement_key] = requirement
		combined_skill_values += requirement

		# Iterates skill_number
		skill_number += 1

	# Adjusts the difficulty level of the state based on the combined_skill_values count
	if combined_skill_values > 9:
		current_state["difficulty_level"] = 3
	elif combined_skill_values > 5:
		current_state["difficulty_level"] = 2
	else:
		current_state["difficulty_level"] = 1

	# Choose reward amount based on the difficulty level
	current_state["reward_amount"] = selected_poi_database["reward_range"][
		current_state["difficulty_level"] - 1
	]

	# Add interaction markers based on difficulty level
	for index in range(1, current_state["difficulty_level"] + 1):
		var marker: Marker2D = get_node("InteractableMarker" + str(index))
		var interactable = interactable_square.instantiate()

		# Add the marker and an interactable square, move it to the correct location, and append to interactables array
		marker.add_child(interactable)
		interactable.global_position = marker.global_position
		interactables.append(interactable)

	# Gives the shelf icons based on the required skills and its shelf type
	skill_icon_1.play(current_state["skill_1"])
	skill_icon_2.play(current_state["skill_2"])
	shelf_type_icon.play(current_state["name"])


# Chooses a random value from any given array
func _choose_random_value(values: Array) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)]


func _on_button_pressed() -> void:
	# If the challenge has already been resolved, exit function
	if is_resolved:
		return

	# Run function to get an array of all assigned companions
	var assigned_companions := _get_assigned_companions()

	# Checks for POIs with no companions––auto-fails them, applies penalties, exits function
	if assigned_companions.is_empty():
		# An ignored hazard still triggers its penalty immediately.
		if current_state["name"] == "hazard":
			_apply_unassigned_hazard_failure()
		# If the shelf wasn't a hazard, just hide the icon
		else:
			shelf_type_icon.visible = false
		return

	# Sets shelves with companions interacted to be ready to interact with to see result
	is_ready = true
	shelf_type_icon.visible = true
	shelf_type_icon.play("interact_ready")


func _on_mouse_entered() -> void:
	# If the shelves are locked, the shelf isn't is_ready or is already resolved, exit function
	if not global.is_locked or not is_ready or is_resolved:
		return

	# Each new POI takes ownership of the one shared hover reference.
	# This makes the most recently entered overlapping icon the active one.
	# If there was a hovered POI before this, set previous to this to keep track
	var previous: Node = global.hovered_point_of_interest

	# If hovering over a valid object that wasn't what was previous hovered, remove hover from previous
	if is_instance_valid(previous) and previous != self:
		previous._set_hovered(false)

	# Set hovered status to currently hovered object
	global.hovered_point_of_interest = self
	_set_hovered(true)


func _on_mouse_exited() -> void:
	# Exiting an older, overlapped Area2D must not clear the newer one.
	# When exiting a hovered POI, remove the global indicator and hover status
	if global.hovered_point_of_interest == self:
		global.hovered_point_of_interest = null
		_set_hovered(false)


# Function to change shelf icon size/color when hovered over
func _set_hovered(value: bool) -> void:
	is_hovered = value
	shelf_type_icon.modulate = Color.INDIAN_RED if value else Color.WHITE
	shelf_type_icon.scale = Vector2(1.05, 1.05) if value else Vector2.ONE


func _open_skill_check() -> void:
	# Get all assigned companions; if no companions, exit
	var assigned_companions := _get_assigned_companions()
	if assigned_companions.is_empty():
		return

	# set skill_check_open to true and remove hover
	skill_check_open = true
	_set_hovered(false)

	# Set up an array that has all assigned companions
	var all_companions: Array[Node] = []
	all_companions.assign(get_tree().get_nodes_in_group("companions"))

	# Begin the skill_check scene and add it to the current scene, let us know when it finishes
	var skill_check = SKILL_CHECK_SCENE.instantiate()
	get_tree().current_scene.add_child(skill_check)
	skill_check.finished.connect(_on_skill_check_finished)

	# Initializes shelf sprite for new scene
	var shelf_sprite: Sprite2D = FrontShelf if FrontShelf.visible else SideShelf
	
	# Sets up skill check scene based on the relevant skill chek state, companions, shelf, etc
	skill_check.setup(
		current_state,
		assigned_companions,
		all_companions,
		shelf_sprite.texture,
		shelf_sprite.flip_h
	)


# When a skill check is finished, close the skill check after the skill-check finishes
func _on_skill_check_finished(succeeded: bool) -> void:
	skill_check_open = false

	# Run the result on the next frame, after the skill-check overlay closes.
	call_deferred("_finish_skill_check", succeeded)


# When the skill check is finished, apply results and complete challenge
func _finish_skill_check(succeeded: bool) -> void:
	_apply_skill_check_result(succeeded)
	_complete_challenge()


func _apply_skill_check_result(succeeded: bool) -> void:
	# Success on hazards has nothing happen, success on others brings an award and exits function
	if succeeded:
		if current_state["name"] == "hazard":
			print("Hazard succeeded. Nothing happens.")
		else:
			print(
				"Challenge reward: ",
				current_state["reward_amount"],
				" ",
				current_state["reward"]
			)
		return

	# Applies failure and exits function if the current state was a hazard
	if current_state["name"] == "hazard":
		_apply_assigned_hazard_failure()
		return

	# Gets assigned companions and has them lose sanity due to failure
	var assigned_companions := _get_assigned_companions()
	for companion in assigned_companions:
		companion.lose_sanity(1)

	print("Challenge failed. Assigned companions lose 1 sanity.")


func _apply_assigned_hazard_failure() -> void:
	# Penalty is based on what the reward would have been
	var penalty_amount: int = current_state["reward_amount"]

	if current_state["reward"] == "steps":
		global.steps = maxi(0, global.steps - penalty_amount)
		print(
			"Hazard failed. Lost ",
			penalty_amount,
			" steps. Steps remaining: ",
			global.steps
		)
	else:
		var all_companions: Array[Node] = []
		all_companions.assign(get_tree().get_nodes_in_group("companions"))

		for companion in all_companions:
			companion.lose_sanity(1)

		print("Hazard failed. Every companion loses 1 sanity.")


func _complete_challenge() -> void:
	# Sets that the room is resolved (not ready) and hides shelf icons that are resolved
	is_resolved = true
	is_ready = false
	shelf_type_icon.visible = false

	if global.hovered_point_of_interest == self:
		global.hovered_point_of_interest = null

	# Undoes any changes from hovering mouse over things
	_set_hovered(false)


func _apply_unassigned_hazard_failure() -> void:
	# Get all companions, determines penalty amount based on reward amount
	var all_companions: Array[Node] = []
	all_companions.assign(get_tree().get_nodes_in_group("companions"))
	var penalty_amount: int = current_state["reward_amount"]

	# If the penalty is steps, then subtract steps
	if current_state["reward"] == "steps":
		global.steps = maxi(0, global.steps - penalty_amount)
		print(
			"Hazard had no assigned companion. Lost ",
			penalty_amount,
			" steps. Steps remaining: ",
			global.steps
		)
	# Otherwise, lose sanity
	else:
		for companion in all_companions:
			companion.lose_sanity(1)
		print(
			"Hazard had no assigned companion. Every companion loses ",
			penalty_amount,
			" sanity."
		)

	_complete_challenge()


# Gets all of the assigned companions for each interactable
func _get_assigned_companions() -> Array[Node]:
	var companions: Array[Node] = []

	for interactable in interactables:
		if interactable.companion != null:
			companions.append(interactable.companion)

	return companions

func _find_button_recursive(current_node: Node) -> Button:
	if current_node is Button:
		return current_node

	# If the current node is not a button and has children search through its children until you find a button
	for child in current_node.get_children():
		var result := _find_button_recursive(child)
		if result:
			return result

	# If neither the current node nor any children (or grand-children, and so on) are buttons, return null
	return null
