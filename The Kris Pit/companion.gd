extends Node2D


var current_position: Vector2
var draggable: bool = false
var is_inside_droppable: bool = false
var body_ref

var initial_position: Vector2
var offset: Vector2
@onready var area_2D: Area2D = $Area2D

func _ready() -> void:
	area_2D.mouse_entered.connect(_on_mouse_entered)
	area_2D.mouse_exited.connect(_on_mouse_exited)
	area_2D.body_entered.connect(_on_area_2d_body_entered)
	area_2D.body_exited.connect(_on_area_2d_body_exited)

func _process(_delta: float) -> void:
	if draggable:
		if Input.is_action_just_pressed("left_click"):
			initial_position = global_position
			offset = get_global_mouse_position() - global_position
			global.is_dragging = true
		if Input.is_action_pressed("left_click"):
			global_position = get_global_mouse_position() - offset
			print("ding!")
		elif Input.is_action_just_released("left_click"):
			global.is_dragging =false
			var tween = get_tree().create_tween()
			if is_inside_droppable:
				tween.tween_property(self, "position", body_ref.position,0.2).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self, "global_position", initial_position,0.2).set_ease(Tween.EASE_OUT)

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
