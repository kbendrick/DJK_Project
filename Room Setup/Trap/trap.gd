extends Area2D

var player: CharacterBody2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.body_entered.connect(on_body_entered)
	pass # Replace with function body.

func on_body_entered(body: CharacterBody2D):
	body.inventory.update_resource("steps", -3)
