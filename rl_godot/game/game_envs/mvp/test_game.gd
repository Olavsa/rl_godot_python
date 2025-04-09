extends Node2D

signal obstacle_hit

func _on_area_2d_area_entered(area: Area2D) -> void:
		emit_signal("obstacle_hit")
