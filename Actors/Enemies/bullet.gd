# bullet.gd
extends Area2D

@onready var lifetimer = $LifeTimer

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var custom_texture: Texture2D = null

@onready var sprite = $Sprite2D

func _ready() -> void:
	if custom_texture != null and sprite:
		sprite.texture = custom_texture

func _physics_process(delta: float):
	global_position += direction * speed * delta


func _on_body_entered(body):
	if body.has_method("lose_life"):
		body.lose_life()
		
		queue_free()
	
func _on_visible_on_screen_enabler_2d_timeout() -> void:
	queue_free()
