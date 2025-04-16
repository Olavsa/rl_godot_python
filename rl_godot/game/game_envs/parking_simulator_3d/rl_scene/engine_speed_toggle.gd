extends Node


@onready var rl_parking_game: RLGodotGame = $".."

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_speed"):
		print("speed changed")
		rl_parking_game.toggle_engine_speed()
