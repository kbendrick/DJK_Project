extends Area2D

@onready var click_area: Area2D = $ClickArea
@onready var bookshelf_sprite: Sprite2D = $Sprite2D
@onready var state_label: Label = $StateLabel

var step_modifier: int = 0

func _ready() -> void:
	# Allow bookshelf to recognize when mouse enters/exits
	click_area.mouse_entered.connect(on_mouse_entered)
	click_area.mouse_exited.connect(on_mouse_exited)

func on_mouse_entered() -> void:
	# Highlight bookshelf chartreuse when mouse hovers
	bookshelf_sprite.self_modulate = Color.CHARTREUSE
	pass

func on_mouse_exited() -> void:
	# Unhighlight upon exit
	bookshelf_sprite.self_modulate = Color.WHITE
	pass

func set_state(state: String) -> void:
	state_label.text = state
	
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

func get_state() -> int:
	# Send step_modifier to player
	return step_modifier
