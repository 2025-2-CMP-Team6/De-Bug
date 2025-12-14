#virus.gd
#owner: Choi eunyoung

extends BaseEnemy

#region Config Variables
@export var move_speed: float = 50.0
@export var attack_range: float = 100.0 # Range
@export var attack_cooldown: float = 3.0

# State variables
var is_attacking: bool = false
var on_cooldown: bool = false
var patrol_direction: int = 1
var patrol_timer: float = 0.0
#endregion

#region Node References
@onready var main_sprite = $Visuals/AnimatedSprite2D
@onready var wave_effect = $ShockwaveHolder/AttakVisual
@onready var attack_area = $ShockwaveHolder/AttakArea
#endregion

func _ready():
	super._ready()
	
	wave_effect.visible = false
	attack_area.monitoring = false
	
	# When the wave animation ends
	if not wave_effect.animation_finished.is_connected(_on_wave_finished):
		wave_effect.animation_finished.connect(_on_wave_finished)
	
	# When the player touches the wave
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		
	# When the main body animation frame changes
	if not main_sprite.frame_changed.is_connected(_on_main_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_main_sprite_frame_changed)

func _process_movement(delta):
	# Stop in place if attacking or dead
	if is_attacking or current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# Stop (or wander) during cooldown
	if on_cooldown:
		velocity.x = move_toward(velocity.x, 0, 100 * delta)
		main_sprite.play("idle")
		return

	# Find the player
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		# [Case 1] Within attack range -> start attack
		if dist <= attack_range:
			start_attack_sequence()
			
		# [Case 2] Chase (within 4x attack range)
		elif dist <= (attack_range * 4.0):
			chase_player(player)
			
		# [Case 3] Too far -> patrol
		else:
			patrol_behavior(delta)
	else:
		patrol_behavior(delta)

	# Flip direction (sprite horizontal flip)
	if velocity.x != 0:
		main_sprite.flip_h = (velocity.x < 0)


func chase_player(player):
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed
	main_sprite.play("walk")

func patrol_behavior(delta):
	patrol_timer -= delta
	
	# Change behavior every 0.5 ~ 1.0 seconds (shuffle around)
	if patrol_timer <= 0:
		patrol_timer = randf_range(0.5, 1.0)
		var random_choice = randi() % 5
		
		# Stop if 0 or 1 (40% chance)
		if random_choice <= 1:
			patrol_direction = 0
		# 2: right, 3: left
		elif random_choice == 2:
			patrol_direction = 1
		elif random_choice == 3:
			patrol_direction = -1
		# 4: turn to the opposite direction
		else:
			patrol_direction = - patrol_direction
			
	velocity.x = patrol_direction * (move_speed * 0.5)
	
	if velocity.x == 0:
		main_sprite.play("idle")
	else:
		main_sprite.play("walk")


func start_attack_sequence():
	is_attacking = true
	on_cooldown = true
	velocity = Vector2.ZERO # Stop moving
	
	main_sprite.play("shockwave")

# Frame detection function
func _on_main_sprite_frame_changed():
	# If currently playing 'shockwave' and the frame is 4 (red), then...
	if main_sprite.animation == "shockwave" and main_sprite.frame == 4:
		fire_wave_effect()

# Fire the wave
func fire_wave_effect():
	# Show & play the wave
	wave_effect.visible = true
	wave_effect.frame = 0
	wave_effect.play("wave")
	
	# Enable attack detection (for player damage)
	attack_area.monitoring = true

# Called when the wave animation ends
func _on_wave_finished():
	wave_effect.visible = false
	wave_effect.stop()
	attack_area.monitoring = false
	
	is_attacking = false
	
	# Return the main body to idle
	main_sprite.play("idle")
	
	# Cooldown wait (3 seconds)
	print("virus cooldown...")
	await get_tree().create_timer(attack_cooldown).timeout
	
	on_cooldown = false
	print("virus cooldown end")

# --- Collision Handling ---

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		print(">> Player hit by wave")
		if body.has_method("lose_life"):
			body.lose_life()

func apply_slow(slow_ratio: float, duration: float):
	print("Argh! My movement speed got slower!")
	move_speed *= slow_ratio # If 0.5 comes in, speed is halved
	
	# Restore after a certain time (use a timer)
	await get_tree().create_timer(duration).timeout
	move_speed /= slow_ratio # Back to normal
