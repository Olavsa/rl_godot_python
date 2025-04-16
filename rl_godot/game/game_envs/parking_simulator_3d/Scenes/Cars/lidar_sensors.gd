extends Node3D

class_name LidarSensors

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_sensor_array():
	var sensor_dist_arr = []
	for sensor: RayCast3D in get_children():
		if not sensor.is_colliding():
			sensor_dist_arr.append(20.0)
		else:
			var origin = Vector2(global_position.x, global_position.z) 
			var collision_point = sensor.get_collision_point()
			collision_point = Vector2(collision_point.x, collision_point.z)
			sensor_dist_arr.append(origin.distance_to(collision_point))
	return sensor_dist_arr
