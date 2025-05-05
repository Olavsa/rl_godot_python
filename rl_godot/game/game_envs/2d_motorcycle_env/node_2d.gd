extends Node2D


@export var engine_speed = 1.0
@export var should_render = true
@export var auto_input = true
var t1: int = -1

func _enter_tree() -> void:
	Engine.time_scale = engine_speed
	Engine.physics_ticks_per_second = 60 * engine_speed
	RenderingServer.render_loop_enabled = should_render


func _physics_process(delta: float) -> void:
	
	if auto_input:
		if Engine.get_physics_frames() > 200:
			Input.action_press("ui_right")
		Input.action_press("ui_up")
	var t = 10
	if t1 == -1:
		t1 = Time.get_ticks_msec()
	elif Engine.get_physics_frames() % (t * 60) == 0:
		#print($Motorcycle.global_position)
		var real_engine_speed = (t * 1000.0) / (Time.get_ticks_msec() - t1)
		t1 = Time.get_ticks_msec()
		
		("engine speed approx: %.1f" % real_engine_speed)
