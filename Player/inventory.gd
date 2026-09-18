extends Node2D

signal resource_count_changed(type: String, new_count: int)

var resources: Dictionary = {
	"steps": 0,
	"sanity": 0,
	"insight": 0,
	"keys": 0
}

func update_resource(type: String, amount: int):
		if(resources.has(type)):
			resources[type] = resources[type] + amount
			emit_signal("resource_count_changed", type, resources[type])
			print(type +": " + str(amount))
func get_resource(type: String) -> int:
	return resources[type]
