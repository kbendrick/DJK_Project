extends Node2D

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

var interactables: Array

var rng = RandomNumberGenerator.new()
var possible_states: Array[String] = ["hazard", "currency", "heal", "mystery", "rest", "upgrade"]
var current_state: Dictionary = {
	"name": null,
	"reward": null,
	"reward_amount": null,
	"skill_1": null,
	"skill_1_value": null,
	"skill_2": null,
	"skill_2_value":null,
	"difficulty_level": null
}

func _ready() -> void:
	
	match shelf_type:
		shelf_types.FrontShelf:
			FrontShelf.visible = true
			SideShelf.visible = false
			POI_Icon.position = Vector2(0,-49)
			interact1.position = Vector2(-48,14)
			interact2.position = Vector2(0, 14)
			interact3.position = Vector2(48,14)
			
		shelf_types.SideShelf:
			FrontShelf.visible = false
			SideShelf.visible = true
			SideShelf.flip_h = Flip_H
			var flip_multi = 1
			if Flip_H:
				flip_multi = -1
			POI_Icon.position = Vector2(0,-125)
			interact1.position = Vector2(33*flip_multi, -9)
			interact2.position = Vector2(33*flip_multi, -44)
			interact3.position = Vector2(33*flip_multi, -79)
			
	var selected_poi_database = POI_database.poi_dict[possible_states[rng.randi_range(0, (possible_states.size()-1))] + "_"+ str(rng.randi_range(1,2))]
	
	for key in selected_poi_database:
		current_state[key] = selected_poi_database[key]
	
	if current_state["name"] == "hazard":
		current_state["skill_1"] = current_state["skill_1"][rng.randi_range(0, current_state["skill_1"].size()-1)]
		current_state["skill_2"] = current_state["skill_2"][rng.randi_range(0, current_state["skill_2"].size()-1)]

	current_state["skill_1_value"] = rng.randi_range(1, 5)
	current_state["skill_2_value"] = rng.randi_range(1, 5)
	
	var combined_skill_values = current_state["skill_1_value"] + current_state["skill_2_value"]
	
	if combined_skill_values > 6:
		current_state["difficulty_level"] = 3
	elif combined_skill_values > 3:
		current_state["difficulty_level"] = 2
	else:
		current_state["difficulty_level"] = 1
	
	current_state["reward_amount"] = selected_poi_database["reward_range"][current_state["difficulty_level"]-1]
	
	for i in range(1, current_state["difficulty_level"]+1):
		var marker = get_node("InteractableMarker" + str(i))
		var interactable = interactable_square.instantiate()
		
		marker.add_child(interactable)
		interactables.append(interactable)
		interactable.global_position = marker.global_position
		
	skill_icon_1.play(current_state["skill_1"])
	skill_icon_2.play(current_state["skill_2"])
	shelf_type_icon.play(current_state["name"])

func _process(_delta: float) -> void:
	if global.is_locked:
		shelf_type_icon.play("interact_ready")
