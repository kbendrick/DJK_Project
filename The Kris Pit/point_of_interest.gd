extends Node2D

enum shelf_types {FrontShelf, SideShelf}

@export var shelf_type: shelf_types = shelf_types.FrontShelf

@onready var FrontShelf: Sprite2D = $FrontShelf
@onready var SideShelf: Sprite2D = $SideShelf
@onready var POI_Icon: AnimatedSprite2D = $POI_Icon

@onready var interact1: Marker2D = $InteractableMarker1
@onready var interact2: Marker2D = $InteractableMarker2
@onready var interact3: Marker2D = $InteractableMarker3

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
			POI_Icon.position = Vector2(0,-125)
			interact1.position = Vector2(33, -9)
			interact2.position = Vector2(33, -44)
			interact3.position = Vector2(33, -79)
