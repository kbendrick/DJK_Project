extends Node2D

var mouse_hovering: Area2D = null
var nearby_bookshelves: Array[Area2D]
@onready var mouse_area: Area2D = $MouseArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_area.area_entered.connect(on_area_entered)
	mouse_area.area_exited.connect(on_area_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Set global position to mouse position
	self.global_position = get_global_mouse_position()
	
func on_area_entered (area: Area2D):
	mouse_hovering = area

func on_area_exited (_area: Area2D):
	mouse_hovering = null
	
func get_mouse_hover() -> Area2D:
	return mouse_hovering
