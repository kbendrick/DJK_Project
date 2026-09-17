extends Node2D

@onready var step_label: Label = $HUD/StepLabel
@onready var player: CharacterBody2D = %Player
@onready var room_setup: Node2D = $RoomSetup
@export var map: TileMapLayer
var astar_grid: AStarGrid2D

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
	
	room_setup.setup()

func _physics_process(_delta: float) -> void:
	step_label.text = "Steps: " + str(player.get_stat("steps"))
