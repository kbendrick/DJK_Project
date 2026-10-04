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

		# If a companion is just left-clicked...
		if Input.is_action_just_pressed("left_click"):
			# Keep track of their initial position and how far away they're dragged
			initial_position = global_position
			drag_offset = get_global_mouse_position() - global_position

			# Set their .is_dragging state to true and hide their stat panel
			global.is_dragging = true
			show_panel = false

			# A companion being moved no longer occupies its previous square.
			# If there was an assigned drop area, indicate that it no longer has a companion and then remove the area
			if assigned_drop_area != null:
				assigned_drop_area.companion = null
				assigned_drop_area = null

			_select_most_recent_drop_area()

		# If the companion is still left-clicked
		if Input.is_action_pressed("left_click"):
			# Hide the panel and keep track of global position
			show_panel = false
			global_position = get_global_mouse_position() - drag_offset

		# If the left-clicked companion is no longer left-clicked
		elif Input.is_action_just_released("left_click"):
			# Set .is_dragging to false and create a tween to place them in a locked position
			global.is_dragging = false
			var tween := create_tween()

			# If there's an active_drop_area
			if active_drop_area != null and active_drop_area.companion == null:
				# Set the tween to adjust the global_position of the companion back to the active drop area over .2s
				tween.tween_property(
					self,
					"global_position",
					active_drop_area.global_position,
					0.2
				).set_ease(Tween.EASE_OUT)

				# Set the active_drop_area to where the companion is and the assigned_drop_area to the same
				active_drop_area.companion = self
				assigned_drop_area = active_drop_area

			# If there's no active_drop_area
			else:
				# Set the tween to adjust the global_position of the companion back to original position
				tween.tween_property(
					self,
					"global_position",
					initial_position,
					0.2
				).set_ease(Tween.EASE_OUT)

			_clear_drop_area_highlights()
	
	# If the companion can be draggable and is set to a position, set the panel to be showable on mouseover
	if draggable and global.is_locked:
		show_panel = true
	
	# If show_panel is true, show the stat_panel
	stat_panel.visible = show_panel

	# Set all displayed stats
	if not hurt:
		sanity_bar.visible = show_panel
	perception_label.text = str(perception)
	charisma_label.text = str(charisma)
	study_label.text = str(study)
	cult_label.text = str(cult)
	medicine_label.text = str(medicine)
	sanity_bar.set_current_sanity(sanity)


# When the mouse hovers over a companion...
func _on_mouse_entered() -> void:
	# If the companion isn't being dragged, enable it to be dragged and scale it as desired
	if not global.is_dragging:
		draggable = true
		scale = Vector2(1.05, 1.05)


# When the mouse exits hovering over a companion...
func _on_mouse_exited() -> void:
	# If the companion isn't being dragged, prevent it from being draggable and scale it back to normal
	if not global.is_dragging:
		draggable = false
		scale = Vector2.ONE


# When a StaticBody2D enters a 2D area...
func _on_area_2d_body_entered(body: StaticBody2D) -> void:
	# If you can't drop something into here, exit function
	if not body.is_in_group("dropable"):
		return

	# If the body isn't in the overlapping_drop_areas, add it to the array
	if not overlapping_drop_areas.has(body):
		overlapping_drop_areas.append(body)

	# If a companion is being dragged, set the active drop area to where they are
	if global.is_dragging and body.companion == null:
		_set_active_drop_area(body)


# When a StaticBody2D exits a 2D area...
func _on_area_2d_body_exited(body: StaticBody2D) -> void:
	# If you can't drop something into here, exit function
	if not body.is_in_group("dropable"):
		return

	#  Remove exited area from overlapping_drop_areas and unhighlight
	overlapping_drop_areas.erase(body)
	_set_drop_area_highlight(body, false)

	if active_drop_area == body:
		active_drop_area = null
		_select_most_recent_drop_area()


func _set_active_drop_area(new_area: StaticBody2D) -> void:
	# Only one overlapping square is allowed to look active.
	# If there is a currently active drop area and it's not the new area, deactivate the current active area
	if active_drop_area != null and active_drop_area != new_area:
		_set_drop_area_highlight(active_drop_area, false)

	# Set the active area to this new area
	active_drop_area = new_area
	_set_drop_area_highlight(active_drop_area, true)


func _select_most_recent_drop_area() -> void:
	active_drop_area = null

	# If a companion isn't being dragged, exit the function
	if not global.is_dragging:
		return

	#? Go through all overlapping drop areas backwards?
	for index in range(overlapping_drop_areas.size() - 1, -1, -1):
		var area := overlapping_drop_areas[index]

		# If this is a valid Object and there isn't a companion there, set it as the active drop area
		if is_instance_valid(area) and area.companion == null:
			_set_active_drop_area(area)
			return


func _clear_drop_area_highlights() -> void:
	# Iterate through all overlapping drop areas and un-highlight them
	for area in overlapping_drop_areas:
		if is_instance_valid(area):
			_set_drop_area_highlight(area, false)

	# Remove any active drop area
	active_drop_area = null


func _set_drop_area_highlight(area: StaticBody2D, highlighted: bool) -> void:
	# False un-highlights the drop area, true highlights it
	if area.has_method("set_highlighted"):
		area.set_highlighted(highlighted)


func get_companion_name() -> String:
	return CompanionList.keys()[companion]


func get_stat_value(stat_name: String) -> int:
	# Based on string input, return stat name; if no stats match, return 0
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
	# Lower sanity stat, change bar accordingly
	sanity = maxi(0, sanity - amount)
	sanity_bar.set_current_sanity(sanity)

	# Play the hurt animation to show injury, display lowered sanity bar
	animated_sprite.play(companion_name.to_lower() + "_hurt")
	hurt = true
	sanity_bar.visible = true
	await animated_sprite.animation_finished

	# Return to idle animation and hide sanity bar
	animated_sprite.play(companion_name.to_lower() + "_idle")
	sanity_bar.visible = false
	hurt = false
