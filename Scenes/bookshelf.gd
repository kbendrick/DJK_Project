extends Area2D

@onready var click_area: Area2D = $ClickArea
@onready var bookshelf_sprite: Sprite2D = $Sprite2D
@onready var state_label: Label = $StateLabel

var step_modifier: int = 0
var current_state: String

func _ready() -> void:
	# Allow bookshelf to recognize when mouse enters/exits
	click_area.mouse_entered.connect(on_mouse_entered)
	click_area.mouse_exited.connect(on_mouse_exited)

func on_mouse_entered() -> void:
	# Highlight bookshelf chartreuse when mouse hovers
	if current_state != "used":
		bookshelf_sprite.self_modulate = Color.CHARTREUSE

func on_mouse_exited() -> void:
	# Unhighlight upon exit
	if current_state != "used":
		bookshelf_sprite.self_modulate = Color.WHITE
	pass

func set_state(state: String) -> void:
	state_label.text = state
	current_state = state
	# Change step_modifier based on bookshelf state
	match state:
		"very bad":
			step_modifier = -10
		"bad":
			step_modifier = -5
		"neutral":
			step_modifier = 0
		"good":
			step_modifier = 5
		"very good":
			step_modifier = 10
		"used":
			step_modifier = 0

func interact(player: CharacterBody2D) -> void:
	if current_state != "used":
		player.update_stat("steps", step_modifier)
		current_state = "used"
		bookshelf_sprite.self_modulate = Color.DARK_RED
