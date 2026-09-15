extends CharacterBody2D

const SPEED := 200.0
const WAYPOINT_TOLERANCE := 4.0

var grid: AStarGrid2D

var current_cell := Vector2i.ZERO
var target_cell := Vector2i.ZERO

var move_pts: PackedVector2Array = PackedVector2Array()
var cur_pt := 0

@onready var step_decrement: Label = $StepDecrement

var moving := false:
	set(value):
		moving = value
		$PathPreviz.visible = not moving
		set_physics_process(moving)


func _ready():
	moving = false
	step_decrement.visible = false

func setup(_grid: AStarGrid2D):
	grid = _grid

	current_cell = pos_to_cell(global_position)
	target_cell = current_cell


func pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(pos.x / grid.cell_size.x),
		floori(pos.y / grid.cell_size.y)
	)


func _input(event: InputEvent):

	# Don't allow the mouse to replace our path
	# while we're currently following it.
	if moving:
		return

	if grid == null:
		return

	if event is InputEventMouseMotion:
		update_path_preview()

	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			start_move()


func update_path_preview():

	var mouse_pos := get_global_mouse_position()
	var target := pos_to_cell(mouse_pos)
	
	step_decrement.global_position = Vector2((mouse_pos.x - 95), (mouse_pos.y - 45))
	
	# Don't recalculate if we're still hoveringx
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
	update_step_number_preview(move_pts.size())

func update_step_number_preview (steps: int) -> void:
	steps -= 1
	if steps > 0:
		step_decrement.visible = true
		step_decrement.text = "-" + str(steps) + " STEPS"
	else:
		step_decrement.visible = false

func start_move():

	if move_pts.is_empty():
		return
	step_decrement.visible = false
	# A path generally begins with the cell we're
	# already standing in.
	cur_pt = 0

	moving = true


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

	# SPEED * delta prevents us from overshooting
	# the waypoint during this frame.
	if distance_to_point <= max(
		WAYPOINT_TOLERANCE,
		SPEED * delta
	):
		global_position = next_point

		cur_pt += 1

		if cur_pt >= move_pts.size() - 1:
			finish_move()

		return

	# Always steer from our REAL position toward
	# the next path point.
	var dir := global_position.direction_to(next_point)

	velocity = dir * SPEED

	move_and_slide()


func finish_move():

	velocity = Vector2.ZERO

	if not move_pts.is_empty():
		global_position = move_pts[-1]

	current_cell = target_cell

	move_pts.clear()
	$PathPreviz.clear_points()
	
	step_decrement.visible = true
	moving = false
