extends Node2D

#drag bookshelf scene into inspector
@export var bookshelf: PackedScene
@onready var shelves_layout: Node2D = $ShelvesLayout

var shelves: Array[Area2D] = []

# Random number generation. Could use some sort of seed implementation to check on consistent results?
var rng = RandomNumberGenerator.new()


func setup ():
	
	#catch for failing to attach a bookshelf scene
	if bookshelf == null:
		push_warning("No Bookshelf Scene Assigned")
		return
	
	#check how many markers there are and then
	#create a shelf at each marker by creating 
	for marker in shelves_layout.get_children():
		var shelf: Area2D = (bookshelf.instantiate())
		add_child(shelf)
		shelves.append(shelf)
		
		shelf.global_position = marker.global_position 
	
	#get the state of the shelves
	var shelf_states: Array = set_shelves(shelves.size())
	
	for i in shelves.size():
		shelves[i].set_state(shelf_states[i])
	
func set_shelves(marker_count: int) -> Array: 
	
	# Introduces five possible states of shelves with relative weights below, then initializes array for shelf states
	var possible_states = ["very bad", "bad", "neutral", "good", "very good"]
	var state_weights = PackedFloat32Array([0.25, 0.5, 1, 0.5, 0.25])
	var shelf_states = []

	# For loops to append a shelf state for every marker in a room with rand_weighted
	for marker in range(marker_count):
		shelf_states.append(possible_states[rng.rand_weighted(state_weights)])

	return shelf_states
