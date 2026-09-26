extends Node2D


enum CompanionList {Hilda, Impa, Jack, Olive, Squeaks}

@export var companion: CompanionList = CompanionList.Hilda

var current_position: Vector2
var draggable: bool = false
var is_inside_droppable: bool = false
var body_ref
var initial_position: Vector2
var offset: Vector2

#starting stats
var perception: int
var cult: int
var charisma: int
var study: int
var medicine: int
var sanity: int

@onready var stat_panel: Panel = $Control/Panel
@onready var perception_label: Label = $Control/Panel/GridContainer/Perception/Label
@onready var cult_label: Label = $Control/Panel/GridContainer/Cult/Label
@onready var charisma_label: Label = $Control/Panel/GridContainer/Charisma/Label
@onready var study_label: Label =$Control/Panel/GridContainer/Study/Label
@onready var medicine_label: Label = $Control/Panel/GridContainer/Medicine/Label

@onready var area_2D: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sanity_bar: ProgressBar = $Control/ProgressBar

func _ready() -> void:
	area_2D.mouse_entered.connect(_on_mouse_entered)
	area_2D.mouse_exited.connect(_on_mouse_exited)
	area_2D.body_entered.connect(_on_area_2d_body_entered)
	area_2D.body_exited.connect(_on_area_2d_body_exited)
	
	var selected_companion = companion_database.companion_dict[CompanionList.keys()[companion]]
	
	perception = selected_companion["perception"]
	cult = selected_companion["cult"]
	charisma = selected_companion["charisma"]
	study = selected_companion["study"]
	medicine = selected_companion["medicine"]
	sanity = selected_companion["sanity"]
	
	animated_sprite.play(CompanionList.keys()[companion].to_lower() + "_idle")
	

func _process(_delta: float) -> void:
	var show_panel: bool = false
	if draggable:
		show_panel = true
		if Input.is_action_just_pressed("left_click"):
			initial_position = global_position
			offset = get_global_mouse_position() - global_position
			global.is_dragging = true
			show_panel = false
		if Input.is_action_pressed("left_click"):
			show_panel = false
			global_position = get_global_mouse_position() - offset
		elif Input.is_action_just_released("left_click"):
			global.is_dragging =false
			var tween = get_tree().create_tween()
			if is_inside_droppable:
				tween.tween_property(self, "position", body_ref.position,0.2).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self, "global_position", initial_position,0.2).set_ease(Tween.EASE_OUT)
			
	stat_panel.visible = show_panel
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
		scale = Vector2(1.05,1.05)

func _on_mouse_exited() -> void:
	if not global.is_dragging:
		draggable = false
		scale = Vector2(1,1)
	
func _on_area_2d_body_entered(body:StaticBody2D):
	if body.is_in_group('dropable'):
		is_inside_droppable = true
		body.modulate = Color(Color.REBECCA_PURPLE, 1)
		body_ref = body
		
func _on_area_2d_body_exited(body):
	if body.is_in_group('dropable'):
		is_inside_droppable = false
		body.modulate = Color(Color.MEDIUM_PURPLE, 0.7)
