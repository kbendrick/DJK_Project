extends CharacterBody2D

var grid: AStarGrid2D

var current_cell: Vector2i
var target_cell: Vector2i
var move_pts: Array

func setup(_grid: AStarGrid2D):
	grid = _grid
	current_cell = pos_to_cell(global_position)
	target_cell = current_cell

func pos_to_cell(pos: Vector2):
	return pos / grid.cell_size
	

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		var target = Vector2i(pos_to_cell(event.position))
		if target != target_cell:
			move_pts = grid.get_point_path(current_cell, target)
			move_pts = (move_pts as Array).map(func (p): return p + grid.cell_size / 2.0)
			$PathPreviz.points = move_pts
			target_cell = target
