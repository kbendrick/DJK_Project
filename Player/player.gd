extends CharacterBody2D

const SPEED := 200.0
const WAYPOINT_TOLERANCE := 4.0

var grid: AStarGrid2D

var current_cell := Vector2i.ZERO
var target_cell := Vector2i.ZERO

var move_pts: PackedVector2Array = PackedVector2Array()
var cur_pt := 0

@onready var step_decrement: Label = $StepDecrement
var step_decrement_storage: int = 0

@export var starting_steps: int = 50
@export var starting_sanity: int = 10
@export var starting_insight: int = 3
@export var starting_keys: int = 0

@onready var mouse_node: Node2D = $Mouse
var mousehover: Area2D = null
var adjacent_to_target_cell: bool = false

@onready var inventory: Node2D = $Inventory

# How many previously visited cells remain blocked.
@export_range(0, 100, 1) var blocked_trail_length: int = 10

# The scene containing the X graphic.
@export var blocked_cell_marker_scene: PackedScene

# Ordered from oldest blocked cell -> newest blocked cell.
var blocked_cells: Array[Vector2i] = []

# Lets us find/remove the X corresponding to a particular cell.
var blocked_cell_markers: Dictionary = {}

var moving := false:
	set(value):
		moving = value
		$PathPreviz.visible = not moving
		set_physics_process(moving)


func _ready():
	moving = false
	step_decrement.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func setup(_grid: AStarGrid2D):
	grid = _grid

	current_cell = pos_to_cell(global_position)
	target_cell = current_cell
	
	inventory.update_resource("steps", starting_steps)
	inventory.update_resource("sanity", starting_sanity)
	inventory.update_resource("insight", starting_insight)
	inventory.update_resource("keys", starting_keys)


func pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(pos.x / grid.cell_size.x),
		floori(pos.y / grid.cell_size.y)
	)

func cell_to_pos(cell: Vector2i) -> Vector2:
	return grid.get_point_position(cell) + grid.cell_size / 2.0

func _input(event: InputEvent):

	# Don't allow the mouse to replace our path
	# while we're currently following it.
	if moving:
		return

	if grid == null:
		return

	if event is InputEventMouseMotion:
		update_path_preview()
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and inventory.get_resource("sanity")>0:
				remove_oldest_blocked_trail()
				inventory.update_resource("sanity", -1)
	
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and mousehover == null:
			start_move()
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and mousehover != null:
				if adjacent_to_target_cell:
					mousehover.interact(self)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and mousehover != null and not mousehover.get_state() == "used" and inventory.get_resource("insight") > 0:
			mousehover.reveal_state()
			inventory.update_resource("insight", -1)

func update_path_preview():

	var mouse_pos := get_global_mouse_position()
	var target := pos_to_cell(mouse_pos)
	var player_pos := self.global_position
	var player_current_tile := pos_to_cell(player_pos)
	
	step_decrement.global_position = Vector2((mouse_pos.x - 95), (mouse_pos.y - 45))
	
	update_step_number_preview(move_pts.size())
	adjacent_to_target_cell = is_adjacent(target, player_current_tile)
	
	# Don't recalculate if we're still hovering
	# over the same cell.
	if target == target_cell:
		return

	target_cell = target

	# Don't ask AStar for cells outside its grid.
	if not grid.is_in_boundsv(target):
		move_pts.clear()
		$PathPreviz.clear_points()
		return

	# Don't allow the player to target an obstacle.
	if grid.is_point_solid(target):
		move_pts.clear()
		$PathPreviz.clear_points()
		return

	var raw_path := grid.get_point_path(
		current_cell,
		target
	)

	move_pts.clear()

	for point in raw_path:

		# AStarGrid points sit on the grid coordinates.
		# Adding half the cell size puts us in the
		# center of each cell.
		move_pts.append(
			point + grid.cell_size / 2.0
		)

	$PathPreviz.points = move_pts

func is_adjacent(target: Vector2i, player: Vector2i) -> bool:
	var x_diff = abs(player.x-target.x)
	var y_diff = abs(player.y-target.y)
	
	if (x_diff + y_diff) == 1:
		return true
	if (x_diff + y_diff) == 2:
		return true
	return false
	
func update_step_number_preview (number_of_steps: int) -> void:
	number_of_steps -= 1
	
	if number_of_steps > 0:
		step_decrement.visible = true
		step_decrement.text = "-" + str(number_of_steps) + " STEPS"
		step_decrement_storage = number_of_steps
	else:
		step_decrement.visible = false
		step_decrement_storage = 0

func start_move():

	if move_pts.is_empty():
		return
	step_decrement.visible = false
	update_stat("steps", -step_decrement_storage)
	print("Current Number of Steps: ", get_stat("steps"))
	# A path generally begins with the cell we're
	# already standing in.
	cur_pt = 0

	moving = true

func add_blocked_cell(cell: Vector2i) -> void:
	if blocked_trail_length <= 0:
		return

	# Safety check. We shouldn't normally get duplicates because
	# blocked cells can't be walked onto.
	if blocked_cells.has(cell):
		return

	# Add this cell to our history.
	blocked_cells.append(cell)

	# Make it unavailable to AStar.
	grid.set_point_solid(cell, true)

	# Create the visual X.
	create_blocked_cell_marker(cell)

	# If we've exceeded our maximum trail length,
	# release the oldest cells.
	trim_blocked_trail()


func trim_blocked_trail() -> void:
	while blocked_cells.size() > blocked_trail_length:
		var oldest_cell: Vector2i = blocked_cells.pop_front()

		# Make the old cell walkable again.
		grid.set_point_solid(oldest_cell, false)

		# Remove its X.
		remove_blocked_cell_marker(oldest_cell)

func remove_oldest_blocked_trail()->void:
	if blocked_cells.size() > 0:
		var oldest_cell: Vector2i = blocked_cells.pop_front()
	
		# Make the old cell walkable again.
		grid.set_point_solid(oldest_cell, false)

		# Remove its X.
		remove_blocked_cell_marker(oldest_cell)

func create_blocked_cell_marker(cell: Vector2i) -> void:
	if blocked_cell_marker_scene == null:
		return

	var marker := blocked_cell_marker_scene.instantiate() as Node2D

	# Add it to the player's parent, NOT the player.
	# Otherwise the X would move along with the player.
	get_parent().add_child(marker)

	marker.global_position = cell_to_pos(cell)

	blocked_cell_markers[cell] = marker


func remove_blocked_cell_marker(cell: Vector2i) -> void:
	if not blocked_cell_markers.has(cell):
		return

	var marker: Node = blocked_cell_markers[cell]

	if is_instance_valid(marker):
		marker.queue_free()

	blocked_cell_markers.erase(cell)

func set_blocked_trail_length(new_length: int) -> void:
	blocked_trail_length = max(new_length, 0)
	trim_blocked_trail()

func update_mouse_hover():
	mousehover = mouse_node.mouse_hovering

func _process(_delta:float) -> void:
	update_mouse_hover()

func _physics_process(delta: float):

	if move_pts.is_empty():
		finish_move()
		return

	# Have we reached the final point?
	if cur_pt >= move_pts.size() - 1:
		finish_move()
		return

	var next_point := move_pts[cur_pt + 1]

	var distance_to_point := global_position.distance_to(next_point)

	if distance_to_point <= max(
		WAYPOINT_TOLERANCE,
		SPEED * delta
	):
		# Remember the tile we're leaving.
		var previous_cell := current_cell

		# Move onto the next tile.
		global_position = next_point

		var new_cell := pos_to_cell(global_position)

		# We actually entered a different grid cell.
		if new_cell != previous_cell:

			# The tile behind us becomes blocked.
			add_blocked_cell(previous_cell)

			# IMPORTANT:
			# current_cell now updates EVERY STEP rather
			# than only at the end of the complete path.
			current_cell = new_cell

		cur_pt += 1

		if cur_pt >= move_pts.size() - 1:
			finish_move()

		return

	var dir := global_position.direction_to(next_point)

	velocity = dir * SPEED

	move_and_slide()


func finish_move():

	velocity = Vector2.ZERO

	if not move_pts.is_empty():
		global_position = move_pts[-1]

	current_cell = pos_to_cell(global_position)
	target_cell = current_cell

	move_pts.clear()
	$PathPreviz.clear_points()

	step_decrement.visible = true
	moving = false

func get_stat (stat: String) -> int:
	return inventory.get_resource(stat)
	
func update_stat(stat: String, stat_update: int) -> void:
		inventory.update_resource(stat, stat_update)
