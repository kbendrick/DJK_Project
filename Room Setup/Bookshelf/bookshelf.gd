extends Area2D

@onready var click_area: Area2D = $ClickArea
@onready var bookshelf_sprite: Sprite2D = $Sprite2D
@onready var state_label: TextureRect = $TextureRect
@onready var room: Node2D = self.get_parent()

var current_texture = null

var modifier: int = 0
var current_state: String

func _ready() -> void:
	# Allow bookshelf to recognize when mouse enters/exits
	click_area.mouse_entered.connect(on_mouse_entered)
	click_area.mouse_exited.connect(on_mouse_exited)
	state_label.pivot_offset = state_label.size / 2
	state_label.visible = false

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
	current_state = state
	# Change step_modifier based on bookshelf state
	match state:
		"cursed":
			modifier = randi_range(-2, -1)
			state = "sanity"
			state_label.texture = load("res://#1 - Transparent Icons copy 6.png")
		"steps":
			modifier = randi_range(3, 5)
			state_label.texture = load("res://#1 - Transparent Icons copy.png")
		"keys":
			modifier = 1
			state_label.texture = load("res://#1 - Transparent Icons copy 2.png")
		"sanity":
			modifier = randi_range(1, 3)
			state_label.texture = load("res://#1 - Transparent Icons copy 4.png")
		"insight":
			modifier = randi_range(1, 3)
			state_label.texture = load("res://#1 - Transparent Icons copy 3.png")
		"used":
			modifier = 0

func interact(player: CharacterBody2D) -> void:
	if current_state != "used":
		player.update_stat(current_state, modifier)
		if not state_label.visible:
			state_label.visible = true
		current_state = "used"
		bookshelf_sprite.self_modulate = Color.DIM_GRAY
		room.shelves_used += 1
		for i in range(room.shelves_used):
			room.generate_trap()

func reveal_state()->void:
	state_label.visible = true

func check_rotate () -> void:
	if self.rotation != 0:
		state_label.rotation = 0 - self.rotation
