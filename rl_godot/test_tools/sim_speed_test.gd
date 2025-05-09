extends Node


var t1 = 0
var prev_ticks = 0

func _ready() -> void:
	prev_ticks = Engine.get_physics_frames()
	t1 = Time.get_ticks_msec()

func _process(_delta: float) -> void:
	var t2 = Time.get_ticks_msec()
	var seconds_between = 1
	if t2 - t1 >= seconds_between * 1000:
		var ticks = Engine.get_physics_frames()
		var ticks_per_sec = (ticks - prev_ticks) / seconds_between
		t1 = t2
		prev_ticks = ticks
		var engine_speed_txt = "Speed: %.1fx" % (ticks_per_sec/60.0)
		print(engine_speed_txt)
