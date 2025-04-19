extends Node

@onready var rl_game: RLGodotGame = $"../.."

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_render"):
		rl_game.toggle_render()
