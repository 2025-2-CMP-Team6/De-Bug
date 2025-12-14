# treasure_chest.gd
extends BaseEnemy

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var open_sound: AudioStream
@export var remove_delay: float = 2.0

var is_dead: bool = false

func _ready() -> void:
	super._ready()
	if animated_sprite:
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	pass

func attack() -> void:
	pass

func _on_attack_timer_timeout() -> void:
	pass

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)

	if open_sound:
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = open_sound
		add_child(audio_player)
		audio_player.play()

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("open"):
		animated_sprite.play("open")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	spawn_reward()
	
	emit_signal("enemy_died")
	
	await get_tree().create_timer(remove_delay).timeout
	queue_free()
	
func spawn_reward() -> void:
	var world = get_tree().current_scene
	if world is World:
		world.open_reward_selection()
