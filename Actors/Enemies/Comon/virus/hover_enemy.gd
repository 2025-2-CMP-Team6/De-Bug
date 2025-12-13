class_name Wisp extends BaseEnemy

#region Settings (Bat + Shooting Settings)
@export_group("Movement")
@export var fly_speed: float = 450.0
@export var acceleration: float = 4.0
@export var erratic_intensity: float = 5 # How erratic/irregular the movement is

@export_group("Combat")
@export var preferred_range: float = 500.0 # Distance to maintain
@export var shoot_interval: float = 2.0
@export var bullet_speed: float = 600.0

const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
#endregion

#region Internal Variables
var player: Node2D = null
var shoot_timer: float = 0.0

# ★ Core movement variables for the bat
var target_velocity: Vector2 = Vector2.ZERO
var move_change_timer: float = 0.0
#endregion

#region Node References
@onready var animation = $Visuals/AnimatedSprite2D
#endregion

func _ready():
	super._ready()
	animation.play("idle")
	gravity = 0.0 # Flying type
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	_pick_new_direction()

func _process_movement(delta):
	if not is_instance_valid(player) or current_health <= 0:
		velocity = velocity.lerp(Vector2.ZERO, 2.0 * delta)
		return

	_apply_erratic_movement(delta)
	
	_handle_shooting(delta)

#region Movement Logic

func _apply_erratic_movement(delta: float):
	move_change_timer -= delta
	
	if move_change_timer <= 0:
		_pick_new_direction()
	
	velocity = velocity.lerp(target_velocity, acceleration * delta)

func _pick_new_direction():
	move_change_timer = randf_range(0.05, 0.15)
	
	if not is_instance_valid(player): return

	var dist = global_position.distance_to(player.global_position)
	var dir_to_player = (player.global_position - global_position).normalized()
	
	var base_velocity = Vector2.ZERO
	
	if dist > preferred_range + 50.0:
		base_velocity = dir_to_player * fly_speed
	elif dist < preferred_range - 50.0:
		base_velocity = - dir_to_player * (fly_speed * 1.2)
	else:
		var strafe_dir = Vector2(-dir_to_player.y, dir_to_player.x)
		if randf() > 0.5: strafe_dir = - strafe_dir
		base_velocity = strafe_dir * (fly_speed * 0.5)

	var jitter = Vector2(randf() - 0.5, randf() - 0.5) * fly_speed * erratic_intensity
	
	target_velocity = base_velocity + jitter

#endregion

#region Shooting Logic
func _handle_shooting(delta):
	shoot_timer -= delta
	if shoot_timer <= 0:
		var dist = global_position.distance_to(player.global_position)
		if dist < preferred_range * 1.5:
			shoot_timer = shoot_interval
			shoot_at_player()

func shoot_at_player():
	if not is_instance_valid(player): return
	
	var bullet = BULLET_SCENE.instantiate()
	var dir = (player.global_position - global_position).normalized()
	
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.speed = bullet_speed
	if projectile_texture:
		bullet.custom_texture = projectile_texture
	
	get_tree().current_scene.add_child(bullet)
#endregion
