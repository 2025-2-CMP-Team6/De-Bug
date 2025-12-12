#boss_fire.gd
extends Area2D
var ready_to_damage: bool = false

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	ready_to_damage = true

func _on_body_entered(body):
	if not ready_to_damage:
		return
	if body.has_method("lose_life"):
		body.lose_life()

func _on_life_timer_timeout() -> void:
	queue_free()
