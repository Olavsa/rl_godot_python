extends Node

class_name RLGodotGame


# Settings
@export var human_mode = true
@export var engine_speed: int = 1
@export var should_render = true
@onready var agent: Node = $GameProcess/Motorcycle/Agent


@onready var server_tcp: TCPServerPython = $TCPServerPython
@onready var game_process: GameProcess = $GameProcess

var init_engine_speed: int = 0

func _enter_tree() -> void:
	init_engine_speed = engine_speed
	
	# Apply settings
	Engine.time_scale = float(engine_speed)
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
		server_tcp.stop_server_thread()
		server_tcp.free()
	else:
		print("Starting server...")
		game_process.human_mode = false
		server_tcp.initialize_and_start(game_process)


func toggle_render():
	should_render = not should_render
	RenderingServer.render_loop_enabled = should_render
	
func toggle_engine_speed():
	engine_speed = 1 if init_engine_speed == engine_speed else init_engine_speed

	get_tree().paused = true
	Engine.time_scale = float(engine_speed)
	Engine.physics_ticks_per_second = 60.0 * engine_speed
	get_tree().paused = false
