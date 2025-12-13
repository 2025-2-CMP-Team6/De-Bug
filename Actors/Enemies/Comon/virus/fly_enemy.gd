class_name FlyingEnemy extends BaseEnemy

#region States
enum State {
	WANDER,
	CHASE,
	AIMING,
	LOCK,
	DASH,
	COOLDOWN
}
var current_state: State = State.WANDER
#endregion

#region Settings (Inspector)
@export_group("Movement")
@export var fly_speed: float = 600.0
@export var wander_radius: float = 300.0
@export var surround_radius: float = 80.0

@export_group("Detection")
@export var detect_range: float = 400.0 # Player detection distance
@export var lose_interest_range: float = 600.0 # Distance to switch from CHASE -> WANDER
@export var attack_trigger_range: float = 200.0 # Distance to switch from CHASE -> AIMING

@export_group("Attack")
@export var dash_speed: float = 1800.0
@export var aim_duration: float = 1.0 # Aim time
@export var lock_duration: float = 0.5 # Wait right before dash
@export var dash_duration: float = 0.5 # Dash duration
@export var attack_cooldown: float = 0.25 # Wait time on failure
@export var attack_width: float = 20.0 # Attack warning width
#endregion

#region Internal Variables
var player: Node2D = null
var initial_pos: Vector2
var target_velocity: Vector2 = Vector2.ZERO
var move_change_timer: float = 0.0
var time_alive: float = 0.0

# Timers and vectors for attacking
var state_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var locked_target_pos: Vector2 = Vector2.ZERO

@onready var animation: AnimatedSprite2D = $Visuals/AnimatedSprite2D
#endregion

func _ready():
	super._ready()
	gravity = 0.0 # Remove gravity
	initial_pos = global_position
	
	if animation:
		animation.play("idle")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Starting state
	_change_state(State.WANDER)

func _physics_process(delta: float):
	time_alive += delta
	match current_state:
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.AIMING:
			_process_aiming(delta)
		State.LOCK:
			_process_lock(delta)
		State.DASH:
			_process_dash(delta)
		State.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()
	queue_redraw() # Update attack-range drawing

#region Per-state Logic (1~4)

# WANDER
func _process_wander(delta: float):
	# Move
	_apply_erratic_movement(delta)
	
	# Detect player
	if player and time_alive > 1.0:
		var dist = global_position.distance_to(player.global_position)
		if dist < detect_range:
			_change_state(State.CHASE)

# CHASE
func _process_chase(delta: float):
	# Move
	_apply_erratic_movement(delta)
	
	if player == null:
		_change_state(State.WANDER)
		return

	var dist = global_position.distance_to(player.global_position)
	
	if dist < 50.0:
		var dir_away = (global_position - player.global_position).normalized()
		target_velocity = dir_away * fly_speed
		velocity = velocity.lerp(target_velocity, 5.0 * delta)
		return

	_apply_erratic_movement(delta)
	
	if dist < attack_trigger_range:
		_change_state(State.AIMING)
	elif dist > lose_interest_range:
		_change_state(State.WANDER)

# AIMING
func _process_aiming(delta: float):
	# Stop and face the player
	velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
	if player:
		_update_sprite_facing(player.global_position.x - global_position.x)
	
	state_timer -= delta
	if state_timer <= 0:
		_change_state(State.LOCK)

# LOCK
func _process_lock(delta: float):
	velocity = Vector2.ZERO
	state_timer -= delta
	if state_timer <= 0:
		_change_state(State.DASH)

# DASH
func _process_dash(delta: float):
	velocity = dash_direction * dash_speed
	
	# Collision check
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			_explode(collider) # Self-destruct on success
			return
		else:
			# Failure cooldown
			print("Wall collision! Preparing to return to chase")
			_change_state(State.COOLDOWN)
			return
	
	# Failure cooldown
	state_timer -= delta
	if state_timer <= 0:
		print("Dash missed! Preparing to return to chase")
		_change_state(State.COOLDOWN)

# COOLDOWN
func _process_cooldown(delta: float):
	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	
	state_timer -= delta
	if state_timer <= 0:
		# Return to chase mode when cooldown ends
		_change_state(State.CHASE)

#endregion

#region Movement and Helper Functions

func _apply_erratic_movement(delta: float):
	move_change_timer -= delta
	if move_change_timer <= 0:
		_pick_new_direction()
	
	velocity = velocity.lerp(target_velocity, 4.0 * delta)
	_update_sprite_facing(velocity.x)

func _pick_new_direction():
	move_change_timer = randf_range(0.05, 1.5)
	
	if current_state == State.CHASE and player:
		var random_angle = randf() * TAU
		var min_surround = 40.0
		var random_dist = randf_range(min_surround, surround_radius)
		
		var offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		var target_pos = player.global_position + offset
		target_velocity = (target_pos - global_position).normalized() * fly_speed
		
	elif current_state == State.WANDER:
		move_change_timer = randf_range(0.2, 0.5)
		
		var dist_from_home = global_position.distance_to(initial_pos)
		if dist_from_home > wander_radius:
			var dir_home = (initial_pos - global_position).normalized()
			var jitter = Vector2(randf() - 0.5, randf() - 0.5) * 0.8
			target_velocity = (dir_home + jitter).normalized() * fly_speed
		else:
			var random_dir = Vector2(randf() - 0.5, randf() - 0.5).normalized()
			target_velocity = random_dir * fly_speed

func _change_state(new_state: State):
	current_state = new_state
	
	match new_state:
		State.WANDER:
			_pick_new_direction()
		State.CHASE:
			_pick_new_direction()
		State.AIMING:
			state_timer = aim_duration
			velocity = Vector2.ZERO
		State.LOCK:
			state_timer = lock_duration
			if player:
				locked_target_pos = player.global_position
				dash_direction = (locked_target_pos - global_position).normalized()
			else:
				dash_direction = Vector2.RIGHT
		State.DASH:
			state_timer = dash_duration
		State.COOLDOWN:
			state_timer = attack_cooldown

func _update_sprite_facing(dir_x: float):
	if animation:
		if dir_x > 0: animation.flip_h = true
		elif dir_x < 0: animation.flip_h = false

func _explode(target):
	if target.has_method("lose_life"):
		target.lose_life()
	EffectManager.play_hit_effect(global_position, 2.0)
	die()

func _draw():
	if current_state == State.AIMING and player:
		draw_line(Vector2.ZERO, (player.global_position - global_position).normalized() * attack_trigger_range, Color(1, 0, 0, 0.4), attack_width)
	elif current_state == State.LOCK:
		draw_line(Vector2.ZERO, (locked_target_pos - global_position).normalized() * attack_trigger_range, Color(1, 0, 0, 0.8), attack_width)
#endregion

func apply_slow(slow_ratio: float, duration: float):
	print("Argh! My movement speed got slower!")
	fly_speed *= slow_ratio # If 0.5 comes in, speed is halved
	dash_speed *= slow_ratio
	
	# Restore after a certain time (use a timer)
	await get_tree().create_timer(duration).timeout
	fly_speed /= slow_ratio # Back to normal
	dash_speed /= slow_ratio # Back to normal
