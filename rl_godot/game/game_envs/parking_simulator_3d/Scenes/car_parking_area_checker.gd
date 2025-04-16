extends Node3D

var is_parked = false

func _on_front_area_area_entered(_area: Area3D) -> void:
	#TODO: Remove if agent gets good
	is_parked = true
	if $BackArea.has_overlapping_areas():
		is_parked = true
		
func _on_park_area_exited(_area: Area3D) -> void:
	is_parked = false
