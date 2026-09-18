extends GridContainer

var player_inventory: Node2D
@onready var player : CharacterBody2D = get_tree().get_first_node_in_group("Player")

func _ready():
	player_inventory = player.find_child("Inventory")
	player_inventory.connect("resource_count_changed", _on_player_inventory_resource_count_changed)
	print("Resource Display Ready")
	
func _on_player_inventory_resource_count_changed(type: String, new_count: int)->void:
	var resource_to_update = self.find_child(type)
	resource_to_update.update_count(new_count)
	if new_count == 0:
		resource_to_update.modulate = Color(0.25, 0.25, 0.25)
	else:
		resource_to_update.modulate = Color(1, 1, 1)
