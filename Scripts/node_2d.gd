extends Node2D

@export var map: TileMapLayer
var astar_grid: AStarGrid2D

# Random number generation. Could use some sort of seed implementation to check on consistent results?
var rng = RandomNumberGenerator.new()

func _ready():
	astar_grid = AStarGrid2D.new()
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.cell_size = map.tile_set.tile_size
	astar_grid.region = Rect2(Vector2.ZERO, ceil(get_viewport_rect().size / astar_grid.cell_size))
	astar_grid.update()
	
	for id in map.get_used_cells():
		var data = map.get_cell_tile_data(id)
		if data and data.get_custom_data('obstacle'):
			astar_grid.set_point_solid(id)

	%GridDisplay.grid = astar_grid
	%Player.setup(astar_grid)

func set_shelves(marker_count): 
	# Introduces five possible states of shelves with relative weights below, then initializes array for shelf states
	var possible_states = ["very bad", "bad", "neutral", "good", "very good"]
	var state_weights = PackedFloat32Array([0.25, 0.5, 1, 0.5, 0.25])
	var shelf_states = []

	# For loops to append a shelf state for every marker in a room with rand_weighted
	for marker in marker_count:
		shelf_states.append(possible_states[rng.rand_weighted(state_weights)])

	return shelf_states
	
