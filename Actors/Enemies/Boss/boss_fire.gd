#boss_fire.gd
extends Area2D

func _on_body_entered(body):
	if body.has_method("lose_life"):
		body.lose_life()

func _on_life_timer_timeout() -> void:
	queue_free()
