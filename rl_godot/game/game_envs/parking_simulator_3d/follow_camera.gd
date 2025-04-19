extends Camera3D

@export var target: VehicleBody3D

var target_pos: Vector3
var target_vel: Vector3

func _ready() -> void:
	assert(target != null, "Follow camera: target not set")

func _physics_process(delta: float) -> void:
	target_vel = target_vel.lerp(target.linear_velocity, 2.5 * delta)
	look_at(target.global_position + target_vel/5)
