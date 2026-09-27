extends Node2D


var is_dragging := false
var is_locked := false

# Only this point of interest may display the locked interaction hover.
var hovered_point_of_interest: Node = null

# Temporary prototype storage for hazard penalties.
var steps := 50
