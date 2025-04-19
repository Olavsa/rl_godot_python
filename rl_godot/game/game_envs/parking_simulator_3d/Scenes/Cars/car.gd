extends VehicleBody3D

class_name PlayerCar

@export var park_checker: Node3D

@export var ENGINE_FORCE = 150
@export var MAX_STEER = 0.7
@export var reverse_power_ratio = 1

@export var agent: ParkingAgent = null

var is_parked = false

var throttle: float = 0.0
var wheel_steer: float = 0.0

var initial_position: Vector3
var initial_basis: Basis

func _ready() -> void:
	gravity_scale = 4.0
	assert(park_checker != null, "Park checker not assigned to %s" % str(self))
	
	initial_position = global_position
	initial_basis = global_basis
	

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		agent.reset()
		
	if not $"../../..".human_mode:
		throttle = agent.throttle
		wheel_steer = agent.steering
	else:
		throttle = Input.get_axis("ui_down", "ui_up")
		wheel_steer = Input.get_axis("ui_right", "ui_left")
	steering = move_toward(steering, wheel_steer * MAX_STEER, delta * 10)
	
	if -0.05 <= throttle and throttle <= 0.05:
		brake = 0.1 # Slightly slow down car when coasting so it stops
	elif throttle < 0:
		throttle = throttle * reverse_power_ratio # Reduce throttle when reversing
	if $back_left.get_rpm() * throttle < 0:
		throttle = 0
		brake = 1
	engine_force = throttle * ENGINE_FORCE
	
	if not is_parked \
	and park_checker.is_parked: #and linear_velocity.length_squared() < 0.1:
		is_parked = true
		agent.is_parked = true
		print("\nparked")
		
	#if not agent.collided and get_is_colliding():
	#	agent.collided = true
	
	
		
func reset_car():
	global_position = initial_position
	linear_velocity = Vector3(0.0, 0.0, 0.0)
	angular_velocity = Vector3(0.0, 0.0, 0.0)
	global_basis = initial_basis
	
	engine_force = 0.0
	brake = 0
	
	is_parked = false
	park_checker.is_parked = false
	
	

func get_speed() -> float:
	var avg_rpm = 0.5 * ($front_left.get_rpm() + $front_right.get_rpm())
	if avg_rpm < 0:
		return-linear_velocity.length()
	else:
		return linear_velocity.length()

func get_car_pos() -> Array:
	var pos = global_position
	return [pos.x, pos.z]
	
func get_target_pos() -> Array:
	var target_pos = $"..".target_spot.global_position
	return [target_pos.x, target_pos.z]


func get_distance_to_parking_spot() -> float:
	var target_spot: ParkingSpot = $"..".target_spot
	var target_pos = target_spot.get_sensors_pos()
	var dist = Vector2(target_pos.x - global_position.x, target_pos.z - global_position.z) 
	dist = dist.length()
	return dist

#func get_is_colliding():
	#return get_colliding_bodies().size() > 0
	
func get_sensors_front():
	return $FrontSensors.get_sensor_array()

func get_sensors_back():
	return $BackSensors.get_sensor_array()
	
func get_sensors_middle():
	return $MiddleSensors.get_sensor_array()
	
func get_rotation_basis():
	return [global_basis.z.x, global_basis.z.y, global_basis.z.z]


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("ground"):
		agent.collided = true
