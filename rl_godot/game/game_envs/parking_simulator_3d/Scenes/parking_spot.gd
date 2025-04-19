extends CSGCombiner3D

class_name ParkingSpot

@export var car_scene: PackedScene

var is_target = false

var car: Node3D = null
var sensors: ParkingSensors = null

func _ready() -> void:
	assert(car_scene != null, "Car not placed in parking lot: %s" % self.name)
	if not is_target and car_scene:
			place_car()

func set_as_target():
	is_target = true
	if car:
		car.queue_free()
		car = null
	place_parking_sensors()
	
	
func remove_as_target():
	is_target = false
	remove_sensors()
	replace_car()


func get_sensors_pos():
	assert(sensors != null, "")
	return sensors.center.global_position
	
func remove_sensors():
	if sensors != null:
		sensors.queue_free()
		sensors = null
	
func place_parking_sensors():
	var parking_sensors_scene: PackedScene = preload("res://game/game_envs/parking_simulator_3d/Scenes/parking_sensors.tscn")
	sensors = parking_sensors_scene.instantiate()
	add_child(sensors)
	
func place_car():
	car = car_scene.instantiate()
	add_child(car)
	var should_rotate: bool = randf() > 0.5
	if should_rotate:
		car.rotate_y(PI/2)
	else:
		car.rotate_y(-PI/2)
	
		
func replace_car():
	if car != null:
		car.queue_free()
	if not is_target:
		place_car()
	
#func _ready() -> void:
