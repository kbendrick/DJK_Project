extends Node2D


enum CompanionList {Hilda, Impa, Jack, Olive, Squeaks}

@export var companion: CompanionList = CompanionList.Hilda

var draggable := false
var initial_position: Vector2
var drag_offset: Vector2

# Every drop area currently touching this companion is kept here.
# The final entry is the most recently touched area.
var overlapping_drop_areas: Array[StaticBody2D] = []
var active_drop_area: StaticBody2D = null
var assigned_drop_area: StaticBody2D = null

# Starting stats.
var perception: int
var cult: int
var charisma: int
var study: int
var medicine: int
var sanity: int

var companion_name: String
var hurt: bool = false

@onready var stat_panel: Panel = $Control/Panel
@onready var perception_label: Label = $Control/Panel/GridContainer/Perception/Label
@onready var cult_label: Label = $Control/Panel/GridContainer/Cult/Label
@onready var charisma_label: Label = $Control/Panel/GridContainer/Charisma/Label
@onready var study_label: Label = $Control/Panel/GridContainer/Study/Label
@onready var medicine_label: Label = $Control/Panel/GridContainer/Medicine/Label
@onready var area_2d: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sanity_bar: ProgressBar = $Control/ProgressBar


func _ready() -> void:
	add_to_group("companions")

	area_2d.mouse_entered.connect(_on_mouse_entered)
	area_2d.mouse_exited.connect(_on_mouse_exited)
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)

	companion_name = CompanionList.keys()[companion]
	var selected_companion = companion_database.companion_dict[companion_name]

	perception = selected_companion["perception"]
	cult = selected_companion["cult"]
	charisma = selected_companion["charisma"]
	study = selected_companion["study"]
	medicine = selected_companion["medicine"]
	sanity = selected_companion["sanity"]

	animated_sprite.play(companion_name.to_lower() + "_idle")


func _process(_delta: float) -> void:
	var show_panel := false

	if draggable and not global.is_locked:
		show_panel = true

		if Input.is_action_just_pressed("left_click"):
			initial_position = global_position
			drag_offset = get_global_mouse_position() - global_position
			global.is_dragging = true
			show_panel = false

			# A companion being moved no longer occupies its previous square.
			if assigned_drop_area != null:
				assigned_drop_area.companion = null
				assigned_drop_area = null

			_select_most_recent_drop_area()

		if Input.is_action_pressed("left_click"):
			show_panel = false
			global_position = get_global_mouse_position() - drag_offset

		elif Input.is_action_just_released("left_click"):
			global.is_dragging = false
			var tween := create_tween()

			if active_drop_area != null and active_drop_area.companion == null:
				tween.tween_property(
					self,
					"global_position",
					active_drop_area.global_position,
					0.2
				).set_ease(Tween.EASE_OUT)

				active_drop_area.companion = self
				assigned_drop_area = active_drop_area
			else:
				tween.tween_property(
					self,
					"global_position",
					initial_position,
					0.2
				).set_ease(Tween.EASE_OUT)

			_clear_drop_area_highlights()
	
	if draggable and global.is_locked:
		show_panel = true
	
	stat_panel.visible = show_panel
	if not hurt:
		sanity_bar.visible = show_panel
	perception_label.text = str(perception)
	charisma_label.text = str(charisma)
	study_label.text = str(study)
	cult_label.text = str(cult)
	medicine_label.text = str(medicine)
	sanity_bar.set_current_sanity(sanity)


func _on_mouse_entered() -> void:
	if not global.is_dragging:
		draggable = true
		scale = Vector2(1.05, 1.05)


func _on_mouse_exited() -> void:
	if not global.is_dragging:
		draggable = false
		scale = Vector2.ONE


func _on_area_2d_body_entered(body: StaticBody2D) -> void:
	if not body.is_in_group("dropable"):
		return

	if not overlapping_drop_areas.has(body):
		overlapping_drop_areas.append(body)

	if global.is_dragging and body.companion == null:
		_set_active_drop_area(body)


func _on_area_2d_body_exited(body: StaticBody2D) -> void:
	if not body.is_in_group("dropable"):
		return

	overlapping_drop_areas.erase(body)
	_set_drop_area_highlight(body, false)

	if active_drop_area == body:
		active_drop_area = null
		_select_most_recent_drop_area()


func _set_active_drop_area(new_area: StaticBody2D) -> void:
	# Only one overlapping square is allowed to look active.
	if active_drop_area != null and active_drop_area != new_area:
		_set_drop_area_highlight(active_drop_area, false)

	active_drop_area = new_area
	_set_drop_area_highlight(active_drop_area, true)


func _select_most_recent_drop_area() -> void:
	active_drop_area = null

	if not global.is_dragging:
		return

	for index in range(overlapping_drop_areas.size() - 1, -1, -1):
		var area := overlapping_drop_areas[index]

		if is_instance_valid(area) and area.companion == null:
			_set_active_drop_area(area)
			return


func _clear_drop_area_highlights() -> void:
	for area in overlapping_drop_areas:
		if is_instance_valid(area):
			_set_drop_area_highlight(area, false)

	active_drop_area = null


func _set_drop_area_highlight(area: StaticBody2D, highlighted: bool) -> void:
	if area.has_method("set_highlighted"):
		area.set_highlighted(highlighted)


func get_companion_name() -> String:
	return CompanionList.keys()[companion]


func get_stat_value(stat_name: String) -> int:
	match stat_name.to_lower():
		"perception":
			return perception
		"cult":
			return cult
		"charisma":
			return charisma
		"study":
			return study
		"medicine":
			return medicine
	return 0


func lose_sanity(amount: int = 1) -> void:
	sanity = maxi(0, sanity - amount)
	sanity_bar.set_current_sanity(sanity)
	animated_sprite.play(companion_name.to_lower() + "_hurt")
	hurt = true
	sanity_bar.visible = true
	await animated_sprite.animation_finished
	animated_sprite.play(companion_name.to_lower() + "_idle")
	sanity_bar.visible = false
	hurt = false
