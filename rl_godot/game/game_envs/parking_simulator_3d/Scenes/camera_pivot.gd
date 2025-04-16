extends Node3D

var direction = Vector3.FORWARD
@export var smooth_speed = 2.5
@export var car: VehicleBody3D
#@onready var car: VehicleBody3D = $".."

func _physics_process(delta: float) -> void:
	var current_velocity = car.linear_velocity
	current_velocity.y = 0
	
	if current_velocity.length_squared() > 1:
		direction = lerp(direction, -current_velocity.normalized(), 2.5 * delta)
		
	global_transform.basis = get_rotation_from_direction(direction)
	
func get_rotation_from_direction(look_direction : Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	
	return Basis(x_axis, Vector3.UP, -look_direction)
