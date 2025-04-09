extends Node


# Settings
@export var human_mode = true
@export var engine_speed = 1.0
@export var should_render = true
@onready var agent: Node = $GameProcess/Motorcycle/Agent


@onready var server_tcp: TCPServerPython = $ServerTCP
@onready var game_process: GameProcess = $GameProcess


func _enter_tree() -> void:
	# Apply settings
	Engine.time_scale = engine_speed
	Engine.physics_ticks_per_second = 60.0 * engine_speed
	RenderingServer.render_loop_enabled = should_render

func _ready() -> void:
	if game_process == null:
		printerr("Game process was null in main scene.")
		get_tree().quit()
		return
		
	if human_mode:
		print("Running in human mode.")
		game_process.human_mode = true
		server_tcp.free()
	else:
		print("Starting server...")
		game_process.human_mode = false
		server_tcp.initialize_and_start(game_process)
