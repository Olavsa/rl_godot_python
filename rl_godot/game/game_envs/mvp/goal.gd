extends Area2D

signal goalReached

func _on_body_entered(_body):
	emit_signal("goalReached")
