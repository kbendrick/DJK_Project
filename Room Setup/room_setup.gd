extends Node2D

#drag bookshelf scene into inspector
@export var bookshelf: PackedScene
@export var trap: PackedScene
@onready var shelves_layout: Node2D = $ShelvesLayout
@onready var traps_layout: Node2D = $TrapsLayout

var global_grid: AStarGrid2D

var shelves: Array[Area2D] = []
var shelves_used: int = 0
var traps: Array[Area2D] = []
var open_cells: Array[Vector2i] = []


# Random number generation. Could use some sort of seed implementation to check on consistent results?
var rng = RandomNumberGenerator.new()

func cell_to_pos(cell: Vector2i) -> Vector2:
	return global_grid.get_point_position(cell) + global_grid.cell_size / 2.0

func setup (grid: AStarGrid2D, player: CharacterBody2D):
	global_grid = grid
	
	#catch for failing to attach a bookshelf scene
	if bookshelf == null:
		push_warning("No Bookshelf Scene Assigned")
		return
	
	#check how many markers there are and then
	#create a shelf at each marker by creating 
	for marker in shelves_layout.get_children():
		var shelf: Area2D = bookshelf.instantiate()
		add_child(shelf)
		shelves.append(shelf)
		
		shelf.global_position = marker.global_position
		shelf.rotate(marker.rotation)
		shelf.check_rotate() 
	
	#get the state of the shelves
	var shelf_states: Array = set_shelves(shelves.size())
	
	for i in shelves.size():
		shelves[i].set_state(shelf_states[i])
	
	get_open_cells(grid, player)
	
func set_shelves(marker_count: int) -> Array: 
	
	# Introduces five possible states of shelves with relative weights below, then initializes array for shelf states
	var possible_states = ["very bad", "bad", "neutral", "good", "very good"]
	var state_weights = PackedFloat32Array([0.25, 0.5, 1, 0.5, 0.25])
	var shelf_states = []

	# For loops to append a shelf state for every marker in a room with rand_weighted
	for marker in range(marker_count):
		shelf_states.append(possible_states[rng.rand_weighted(state_weights)])

	return shelf_states

func get_open_cells(grid: AStarGrid2D, player: CharacterBody2D):
	for x in range(grid.region.position.x, grid.region.end.x):
		for y in range(grid.region.position.y, grid.region.end.y):
			var cell = Vector2i(x,y)
			# Check to see if a solid object is in the cell; doesn't add if true
			if grid.is_point_solid(cell):
				continue
			# Check to see if player is on the current cell; adds if true
			if cell == player.current_cell:
				open_cells.append(cell)
				continue
			
			# Checks to see if player can path to this cell; adds if it can path
			var path: Array[Vector2i] = grid.get_id_path(player.current_cell, cell, false)
			if not path.is_empty():
				open_cells.append(cell)
	
func generate_trap():
	# Choose random cell from available cells; return cell and remove from array
	var trap_cell = open_cells.pop_at(rng.randi_range(0, (open_cells.size()-1)))
	
	# Create a trap area, add as child to traps layout, give it a position
	var this_trap: Area2D = trap.instantiate()
	traps_layout.add_child(this_trap)
	traps.append(this_trap)
	
	# Assign a position to the generated trap
	this_trap.global_position = cell_to_pos(trap_cell)
