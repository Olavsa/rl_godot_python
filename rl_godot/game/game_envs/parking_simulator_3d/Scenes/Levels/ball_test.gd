extends Node3D

# Settings
@export var engine_speed: int = 1
@export var should_render = true

func _enter_tree() -> void:
	# Apply settings
	Engine.time_scale = float(engine_speed)
	Engine.physics_ticks_per_second = 60.0 * engine_speed
	RenderingServer.render_loop_enabled = should_render
