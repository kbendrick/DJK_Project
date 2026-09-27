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
	var button := _find_button_recursive(current_scene_root)

	if button:
		button.pressed.connect(_on_button_pressed)

	interact_click_area.mouse_entered.connect(_on_mouse_entered)
	interact_click_area.mouse_exited.connect(_on_mouse_exited)

	_set_shelf_layout()
	_create_random_challenge()


func _process(_delta: float) -> void:
	if is_hovered and is_ready and not skill_check_open:
		if Input.is_action_just_pressed("left_click"):
			_open_skill_check()


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
	var database_key := possible_states[rng.randi_range(0, possible_states.size() - 1)]
	database_key += "_" + str(rng.randi_range(1, 2))
	var selected_poi_database: Dictionary = POI_database.poi_dict[database_key]

	for key in selected_poi_database:
		current_state[key] = selected_poi_database[key]

	if current_state["name"] == "hazard":
		var i: int = rng.randi_range(0, 4)
		current_state["skill_1"] = current_state["skill_1"][i]
		current_state["skill_2"] = current_state["skill_2"][i]

	current_state["skill_1_value"] = rng.randi_range(2, 8)
	current_state["skill_2_value"] = rng.randi_range(2, 8)

	var combined_skill_values: int = (
		current_state["skill_1_value"] + current_state["skill_2_value"]
	)

	if combined_skill_values > 9:
		current_state["difficulty_level"] = 3
	elif combined_skill_values > 5:
		current_state["difficulty_level"] = 2
	else:
		current_state["difficulty_level"] = 1

	current_state["reward_amount"] = selected_poi_database["reward_range"][
		current_state["difficulty_level"] - 1
	]

	for index in range(1, current_state["difficulty_level"] + 1):
		var marker: Marker2D = get_node("InteractableMarker" + str(index))
		var interactable = interactable_square.instantiate()

		marker.add_child(interactable)
		interactable.global_position = marker.global_position
		interactables.append(interactable)

	skill_icon_1.play(current_state["skill_1"])
	skill_icon_2.play(current_state["skill_2"])
	shelf_type_icon.play(current_state["name"])


func _choose_random_value(values: Array) -> Variant:
	return values[rng.randi_range(0, values.size() - 1)]


func _on_button_pressed() -> void:
	if is_resolved:
		return

	var assigned_companions := _get_assigned_companions()

	if assigned_companions.is_empty():
		# An ignored hazard still triggers its penalty immediately.
		if current_state["name"] == "hazard":
			_apply_unassigned_hazard_failure()
		else:
			shelf_type_icon.visible = false
		return

	is_ready = true
	shelf_type_icon.visible = true
	shelf_type_icon.play("interact_ready")


func _on_mouse_entered() -> void:
	if not global.is_locked or not is_ready or is_resolved:
		return

	# Each new POI takes ownership of the one shared hover reference.
	# This makes the most recently entered overlapping icon the active one.
	var previous: Node = global.hovered_point_of_interest
	if is_instance_valid(previous) and previous != self:
		previous._set_hovered(false)

	global.hovered_point_of_interest = self
	_set_hovered(true)


func _on_mouse_exited() -> void:
	# Exiting an older, overlapped Area2D must not clear the newer one.
	if global.hovered_point_of_interest == self:
		global.hovered_point_of_interest = null
		_set_hovered(false)


func _set_hovered(value: bool) -> void:
	is_hovered = value
	shelf_type_icon.modulate = Color.INDIAN_RED if value else Color.WHITE
	shelf_type_icon.scale = Vector2(1.05, 1.05) if value else Vector2.ONE


func _open_skill_check() -> void:
	var assigned_companions := _get_assigned_companions()
	if assigned_companions.is_empty():
		return

	skill_check_open = true
	_set_hovered(false)

	var all_companions: Array[Node] = []
	all_companions.assign(get_tree().get_nodes_in_group("companions"))

	var skill_check = SKILL_CHECK_SCENE.instantiate()
	get_tree().current_scene.add_child(skill_check)
	skill_check.finished.connect(_on_skill_check_finished)

	var shelf_sprite: Sprite2D = FrontShelf if FrontShelf.visible else SideShelf
	skill_check.setup(
		current_state,
		assigned_companions,
		all_companions,
		shelf_sprite.texture,
		shelf_sprite.flip_h
	)


func _on_skill_check_finished(_succeeded: bool) -> void:
	skill_check_open = false
	_complete_challenge()


func _complete_challenge() -> void:
	is_resolved = true
	is_ready = false
	shelf_type_icon.visible = false

	if global.hovered_point_of_interest == self:
		global.hovered_point_of_interest = null

	_set_hovered(false)


func _apply_unassigned_hazard_failure() -> void:
	var all_companions: Array[Node] = []
	all_companions.assign(get_tree().get_nodes_in_group("companions"))
	var penalty_amount: int = current_state["reward_amount"]

	if current_state["reward"] == "steps":
		global.steps = maxi(0, global.steps - penalty_amount)
		print(
			"Hazard had no assigned companion. Lost ",
			penalty_amount,
			" steps. Steps remaining: ",
			global.steps
		)
	else:
		for companion in all_companions:
			companion.lose_sanity(1)
		print(
			"Hazard had no assigned companion. Every companion loses ",
			penalty_amount,
			" sanity."
		)

	_complete_challenge()


func _get_assigned_companions() -> Array[Node]:
	var companions: Array[Node] = []

	for interactable in interactables:
		if interactable.companion != null:
			companions.append(interactable.companion)

	return companions

func _find_button_recursive(current_node: Node) -> Button:
	if current_node is Button:
		return current_node

	for child in current_node.get_children():
		var result := _find_button_recursive(child)
		if result:
			return result

	return null
