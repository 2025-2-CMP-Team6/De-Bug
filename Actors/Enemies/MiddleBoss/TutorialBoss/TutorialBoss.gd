# TutorialBoss.gd
# owner : Shin I Cheol
extends BaseEnemy

#region Config Variables
@export var move_speed: float = 100.0
@export var attack_range: float = 100.0 # Sword attack range (melee) - slightly wider
@export var dash_range: float = 300.0 # Dash range
@export var chase_range: float = 800.0 # Chase range
@export var attack_cooldown: float = 2.0
@export var attack_duration: float = 0.6 # Attack animation length
@export var attack_hit_delay: float = 0.2 # Delay from attack start until damage check

# Boss state enum
enum State {
	IDLE, # Idle / patrol
	CHASE, # Chase player
	ATTACK, # Attacking
	DASH, # Dash attack
	COOLDOWN # Cooldown after attack
}

# State variables
var current_state: State = State.IDLE
var state_timer: float = 0.0 # Per-state timer
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var has_dealt_damage: bool = false # Whether damage was dealt during the current attack
var pattern_timer: Timer
var floor_checker: RayCast2D
#endregion

#region Node References
# Updated to match the current scene structure
@onready var main_sprite = $AnimatedSprite2D # Direct child, without Visuals
@onready var attack_area = get_node_or_null("AttackArea") # Sword hitbox (needs to be added)
#endregion

func _ready():
	super._ready()

	add_to_group("enemies")

	if main_sprite:
		main_sprite.play("idle")
	if attack_area:
		attack_area.monitoring = true

		# Check CollisionShape2D
		var shape_count = 0
		for child in attack_area.get_children():
			if child is CollisionShape2D:
				shape_count += 1
		if shape_count == 0:
			print("  - Warning: No CollisionShape2D found!")

	# Connect signals
	if main_sprite and not main_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if main_sprite and not main_sprite.animation_finished.is_connected(_on_animation_finished):
		main_sprite.animation_finished.connect(_on_animation_finished)

	if attack_area and not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		print("AttackArea.body_entered signal connected")

	# Create RayCast for floor detection
	floor_checker = RayCast2D.new()
	floor_checker.target_position = Vector2(0, 50) # Check downward
	floor_checker.collision_mask = collision_mask # Detect walkable layers (floor)
	floor_checker.enabled = true
	add_child(floor_checker)

	pattern_timer = Timer.new()
	pattern_timer.one_shot = true
	pattern_timer.timeout.connect(_on_pattern_timer_timeout)
	add_child(pattern_timer)
	start_pattern_timer()


func _process_movement(delta):
	# Stop if dead
	if current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# Decrease state timer
	if state_timer > 0:
		state_timer -= delta

	# Find player
	var player = get_tree().get_first_node_in_group("player")

	# State behavior
	match current_state:
		State.IDLE:
			handle_idle_state(delta, player)

		State.CHASE:
			handle_chase_state(delta, player)

		State.ATTACK:
			handle_attack_state(delta)

		State.DASH:
			handle_dash_state(delta, player)

		State.COOLDOWN:
			handle_cooldown_state(delta, player)

	# Flip sprite direction (face the player direction)
	if main_sprite and velocity.x != 0:
		main_sprite.flip_h = (velocity.x < 0)

		# Adjust AttackArea position to match sprite facing direction
		if attack_area:
			if main_sprite.flip_h: # Facing left
				attack_area.position = Vector2(-42, 7.25)
			else: # Facing right
				attack_area.position = Vector2(8, 7.25)

# --- Per-state handler functions ---

func handle_idle_state(delta, player):
	if player:
		var distance = global_position.distance_to(player.global_position)

		# Start chasing if the player enters chase range
		if distance <= chase_range:
			change_state(State.CHASE)
			return

	# Patrol behavior
	patrol_behavior(delta)

func handle_chase_state(delta, player):
	if not player:
		change_state(State.IDLE)
		return

	var distance = global_position.distance_to(player.global_position)

	# Attack if within attack range
	if distance <= attack_range:
		change_state(State.ATTACK)
		return

	# Return to idle if out of chase range
	if distance > chase_range:
		change_state(State.IDLE)
		return

	# Chase the player
	chase_player(player)

func handle_attack_state(delta):
	# Stop while attacking
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# Only check damage after the delay (to match sword swing timing)
	var time_since_attack_start = attack_duration - state_timer
	var should_check_damage = time_since_attack_start >= attack_hit_delay

	# If damage hasn't been dealt yet and delay has passed, check if the player is in AttackArea
	if not has_dealt_damage and should_check_damage and attack_area:
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		print("[DEBUG] ATTACK state (after delay) - elapsed time: ", time_since_attack_start,
			  ", has_dealt_damage: ", has_dealt_damage,
			  ", overlapping_bodies count: ", overlapping_bodies.size(),
			  ", AttackArea pos: ", attack_area.position)

		for body in overlapping_bodies:
			print("[DEBUG] Overlapping body: ", body.name, ", is player?: ", body.is_in_group("player"))
			if body.is_in_group("player"):
				print("=== handle_attack_state: Player detected! Processing damage ===")
				if body.has_method("lose_life"):
					body.lose_life()
					print("Player lose_life() called")
					has_dealt_damage = true
					print("Damage flag set")
					break

	# Switch to cooldown state when the attack animation time ends
	if state_timer <= 0:
		change_state(State.COOLDOWN)

func handle_cooldown_state(delta, player):
	# When cooldown ends, switch to chase or idle
	if state_timer <= 0:
		if player and global_position.distance_to(player.global_position) <= chase_range:
			change_state(State.CHASE)
		else:
			change_state(State.IDLE)
		return

	# Slowly chase the player during cooldown
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= chase_range:
			chase_player(player)
			velocity.x *= 0.5 # Reduce speed to 50%
		else:
			patrol_behavior(delta)
	else:
		patrol_behavior(delta)

func handle_dash_state(delta, player):
	# Return if the current animation isn't dash
	if not main_sprite or main_sprite.animation != "dash":
		return

	var frame = main_sprite.frame
	
	# 2. Charging (frames 0, 1) - stop
	if frame <= 1:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
	# 3. Dashing (frame 2, 3+) - move forward (3x speed)
	else:
		var dir = -1 if main_sprite.flip_h else 1
		
		# Check floor in the movement direction
		if floor_checker:
			floor_checker.position.x = dir * 30 # Forward check distance
			floor_checker.force_raycast_update()
			if not floor_checker.is_colliding():
				velocity.x = 0
				return

		velocity.x = dir * move_speed * 6.0
		
		# Enable AttackArea (collision check)
		if not has_dealt_damage and attack_area:
			var overlapping_bodies = attack_area.get_overlapping_bodies()
			for body in overlapping_bodies:
				if body.is_in_group("player"):
					_on_attack_area_body_entered(body)

# --- Behavior pattern functions ---

func chase_player(player):
	var direction = (player.global_position - global_position).normalized()

	# Floor check while chasing
	if direction.x != 0 and floor_checker:
		var check_dir = 1 if direction.x > 0 else -1
		floor_checker.position.x = check_dir * 30
		floor_checker.force_raycast_update()
		if not floor_checker.is_colliding():
			velocity.x = 0
			if main_sprite: main_sprite.play("idle")
			return

	velocity.x = direction.x * move_speed
	if main_sprite:
		main_sprite.play("move")

func patrol_behavior(delta):
	patrol_timer -= delta

	# Change behavior every 1~2 seconds
	if patrol_timer <= 0:
		patrol_timer = randf_range(1.0, 2.0)
		var random_choice = randi() % 5

		# 40% chance to stop
		if random_choice <= 1:
			patrol_direction = 0
		elif random_choice == 2:
			patrol_direction = 1
		elif random_choice == 3:
			patrol_direction = -1
		else:
			patrol_direction = - patrol_direction

	# If there's no floor while moving, reverse direction
	if patrol_direction != 0 and floor_checker:
		floor_checker.position.x = patrol_direction * 30
		floor_checker.force_raycast_update()
		if not floor_checker.is_colliding():
			patrol_direction *= -1

	velocity.x = patrol_direction * (move_speed * 0.5)

	if main_sprite:
		if velocity.x == 0:
			main_sprite.play("idle")
		else:
			main_sprite.play("move")


func change_state(new_state: State):
	if current_state == new_state:
		return

	print("TutorialBoss: State changed ", State.keys()[current_state], " -> ", State.keys()[new_state])

	# New state start handling
	current_state = new_state
	match new_state:
		State.IDLE:
			state_timer = 0
			if main_sprite:
				main_sprite.play("idle")

		State.CHASE:
			state_timer = 0

		State.ATTACK:
			state_timer = attack_duration
			velocity = Vector2.ZERO
			has_dealt_damage = false # Reset damage flag when starting a new attack
			if main_sprite:
				main_sprite.play("attack")

			# Set AttackArea position based on current facing direction
			if attack_area and main_sprite:
				if main_sprite.flip_h: # Facing left
					attack_area.position = Vector2(-42, 7.25)
				else: # Facing right
					attack_area.position = Vector2(8, 7.25)
		
		State.DASH:
			has_dealt_damage = false
			if main_sprite:
				main_sprite.play("dash")
				
				var player = get_tree().get_first_node_in_group("player")
				if player:
					var dir_x = player.global_position.x - global_position.x
					if dir_x != 0:
						main_sprite.flip_h = (dir_x < 0)
						# Adjust AttackArea position
						if attack_area:
							if main_sprite.flip_h:
								attack_area.position = Vector2(-42, 7.25)
							else:
								attack_area.position = Vector2(8, 7.25)

		State.COOLDOWN:
			velocity = Vector2.ZERO # Remove dash inertia
			state_timer = attack_cooldown
			if main_sprite:
				main_sprite.play("idle")

func _on_sprite_frame_changed():
	pass

func _on_animation_finished():
	if main_sprite.animation == "dash":
		change_state(State.COOLDOWN)

func start_pattern_timer():
	pattern_timer.wait_time = randf_range(1.0, 3.0)
	pattern_timer.start()

func _on_pattern_timer_timeout():
	if current_state == State.IDLE or current_state == State.CHASE:
		if randf() < 0.5:
			change_state(State.DASH)
	start_pattern_timer()


# When the sword attack hits the player
func _on_attack_area_body_entered(body):
	if (current_state != State.ATTACK and current_state != State.DASH) or has_dealt_damage:
		return

	if body.is_in_group("player"):
		if body.has_method("lose_life"):
			body.lose_life()
			has_dealt_damage = true
