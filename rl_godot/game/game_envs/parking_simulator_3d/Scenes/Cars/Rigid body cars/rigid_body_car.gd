extends RigidBody3D

class_name RigidBodyCar

func _enter_tree() -> void:
	mass = 15.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 1.5, 0.0)
	sleeping = true
