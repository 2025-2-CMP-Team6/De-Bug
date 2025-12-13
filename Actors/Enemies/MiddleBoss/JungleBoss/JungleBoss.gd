# JungleBoss.gd
extends BaseEnemy

#region Config Variables
@export var move_speed: float = 80.0
@export var patrol_radius: float = 150.0 # Patrol radius
@export var chase_range: float = 400.0 # Player detection range
@export var attack_range: float = 150.0 # Attack range
@export var attack_cooldown: float = 2.5
@export var attack_duration: float = 1.2 # Attack animation length
@export var blue_hit_frame: int = 2 # Frame where Blue deals damage
@export var purple_hit_frame: int = 2 # Frame where Purple deals damage

# Enrage-related settings
@export var enrage_health_threshold: float = 70.0 # HP threshold to trigger enrage (half)
@export var enraged_move_speed_multiplier: float = 3 # Move speed multiplier while enraged
@export var enraged_attack_cooldown_multiplier: float = 0.1 # Attack cooldown multiplier while enraged
#endregion

#region Boss State Enum
enum State {
	IDLE, # Idle
	WALK, # Patrol / chase
	ATTACK_BLUE, # Blue attack
	ATTACK_PURPLE, # Purple attack
	COOLDOWN # Cooldown after attack
}
#endregion

#region State Variables
var current_state: State = State.IDLE
var state_timer: float = 0.0
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var spawn_position: Vector2 # Spawn position (center point for patrolling)
var attack_phase: int = 0 # 0 = Blue, 1 = Purple

# Damage flags (only deal damage once per head)
var blue_dealt_damage: bool = false
var purple_dealt_damage: bool = false

# Enrage-related variables
var is_enraged: bool = false # Whether enraged
var base_move_speed: float # Base move speed
var base_attack_cooldown: float # Base attack cooldown

var floor_checker: RayCast2D
#endregion

#region Node References
@onready var main_sprite = $AnimatedSprite2D
@onready var sprite_ = $AnimatedSprite2D # Override sprite referenced in BaseEnemy
@onready var attack_area = get_node_or_null("AttackArea")
#endregion

func _ready():
	super._ready()

	add_to_group("enemies")

	# Store spawn position
	spawn_position = global_position

	# Store base values (pre-enrage)
	base_move_speed = move_speed
	base_attack_cooldown = attack_cooldown

	if attack_area:
		attack_area.monitoring = true

		# Check CollisionShape2D
		var shape_count = 0
		for child in attack_area.get_children():
			if child is CollisionShape2D:
				shape_count += 1
		if shape_count == 0:
			print("Warning: AttackArea has no CollisionShape2D!")

	# Connect signals
	if main_sprite and not main_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if main_sprite and not main_sprite.animation_finished.is_connected(_on_animation_finished):
		main_sprite.animation_finished.connect(_on_animation_finished)

	# Create RayCast for floor detection
	floor_checker = RayCast2D.new()
	floor_checker.target_position = Vector2(0, 50)
	floor_checker.collision_mask = collision_mask
	floor_checker.enabled = true
	add_child(floor_checker)

	# Set initial state (initialize timer via change_state)
	change_state(State.IDLE)

	print("JungleBoss initialization complete - position: ", global_position)

func _process_movement(delta):
	# Stop if dead
	if current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# Check enrage (trigger when HP is half or below)
	check_enrage()

	# Decrease state timer
	if state_timer > 0:
		state_timer -= delta

	# Find player
	var player = get_tree().get_first_node_in_group("player")

	# State behavior
	match current_state:
		State.IDLE:
			handle_idle_state(delta, player)

		State.WALK:
			handle_walk_state(delta, player)

		State.ATTACK_BLUE:
			handle_attack_blue_state(delta)

		State.ATTACK_PURPLE:
			handle_attack_purple_state(delta)

		State.COOLDOWN:
			handle_cooldown_state(delta, player)

	# Flip sprite direction (base sprite faces left by default, so invert)
	if main_sprite and velocity.x != 0:
		main_sprite.flip_h = (velocity.x > 0)

		# Adjust AttackArea position to match sprite direction (consider scale 2)
		if attack_area:
			if main_sprite.flip_h: # Facing right (flipped)
				attack_area.position.x = -12
			else: # Facing left (default)
				attack_area.position.x = 12

#region Per-state handler functions

func handle_idle_state(delta, player):
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	if player:
		var distance = global_position.distance_to(player.global_position)

		# Start chasing if player enters detection range
		if distance <= chase_range:
			change_state(State.WALK, player)
			return

	# Start patrolling when the idle timer ends
	if state_timer <= 0:
		change_state(State.WALK)

func handle_walk_state(delta, player):
	var is_chasing = false

	if player:
		var distance = global_position.distance_to(player.global_position)
		# print("WALK state - player distance: ", distance)

		# Start attacking if player enters attack range
		if distance <= attack_range:
			print("Entered attack range! Starting attack")
			start_attack_sequence()
			return

		# Chase if player is within chase range
		if distance <= chase_range:
			print("Chasing - velocity.x: ", velocity.x)
			chase_player(player)
			is_chasing = true

	# If not chasing the player, patrol instead
	if not is_chasing:
		patrol_behavior(delta)

		# Return to idle if too far from spawn position
		var distance_from_spawn = global_position.distance_to(spawn_position)
		if distance_from_spawn > patrol_radius:
			change_state(State.IDLE)

func handle_attack_blue_state(delta):
	# Stop while attacking
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# When the attack animation ends, go to the next attack
	if state_timer <= 0:
		change_state(State.ATTACK_PURPLE)

func handle_attack_purple_state(delta):
	# Stop while attacking
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# When the attack animation ends, go to cooldown
	if state_timer <= 0:
		change_state(State.COOLDOWN)

func handle_cooldown_state(delta, player):
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# When cooldown ends, return to walk state
	if state_timer <= 0:
		if player and global_position.distance_to(player.global_position) <= chase_range:
			change_state(State.WALK, player)
		else:
			change_state(State.IDLE)

#endregion

#region Behavior pattern functions

func chase_player(player):
	var direction = (player.global_position - global_position).normalized()
	print("chase_player called - direction: ", direction, ", move_speed: ", move_speed)

	# Floor check while chasing (temporarily disabled - for debugging)
	# if direction.x != 0 and floor_checker:
	# 	var check_dir = 1 if direction.x > 0 else -1
	# 	floor_checker.position.x = check_dir * 30
	# 	floor_checker.force_raycast_update()
	# 	if not floor_checker.is_colliding():
	# 		print("No floor! Stopping")
	# 		velocity.x = 0
	# 		if main_sprite: main_sprite.play("idle")
	# 		return

	velocity.x = direction.x * move_speed
	print("velocity set: ", velocity.x)
	if main_sprite:
		main_sprite.play("walk")

func patrol_behavior(delta):
	patrol_timer -= delta

	# Change direction every 1~2 seconds
	if patrol_timer <= 0:
		patrol_timer = randf_range(1.0, 2.5)
		var random_choice = randi() % 3

		if random_choice == 0:
			patrol_direction = 0 # Stop
		elif random_choice == 1:
			patrol_direction = 1
		else:
			patrol_direction = -1

	# Reverse direction if there's no floor while moving (temporarily disabled - for debugging)
	# if patrol_direction != 0 and floor_checker:
	# 	floor_checker.position.x = patrol_direction * 30
	# 	floor_checker.force_raycast_update()
	# 	if not floor_checker.is_colliding():
	# 		patrol_direction *= -1

	# If outside patrol radius, head back toward spawn position
	var to_spawn = spawn_position - global_position
	if to_spawn.length() > patrol_radius:
		patrol_direction = 1 if to_spawn.x > 0 else -1

	velocity.x = patrol_direction * (move_speed * 0.4)

	if main_sprite:
		if velocity.x == 0:
			main_sprite.play("idle")
		else:
			main_sprite.play("walk")

#endregion

#region Attack-related

func start_attack_sequence():
	# Start attack sequence (always begin with Blue)
	attack_phase = 0
	change_state(State.ATTACK_BLUE)

func change_state(new_state: State, player = null):
	if current_state == new_state:
		return

	print("JungleBoss: State changed ", State.keys()[current_state], " -> ", State.keys()[new_state])

	# New state start handling
	current_state = new_state
	match new_state:
		State.IDLE:
			state_timer = randf_range(1.0, 2.0)
			if main_sprite:
				main_sprite.play("idle")

		State.WALK:
			state_timer = 0
			if main_sprite:
				main_sprite.play("walk")

		State.ATTACK_BLUE:
			state_timer = attack_duration
			velocity = Vector2.ZERO
			blue_dealt_damage = false # Reset Blue damage flag
			if main_sprite:
				main_sprite.play("attackBlue")

			# Face the player
			var target_player = player if player != null else get_tree().get_first_node_in_group("player")
			if target_player and main_sprite:
				var dir_to_player = target_player.global_position.x - global_position.x
				main_sprite.flip_h = (dir_to_player > 0)

			# Set AttackArea position based on current facing direction (consider scale 2)
			if attack_area and main_sprite:
				if main_sprite.flip_h: # Right (flipped)
					attack_area.position.x = -12
				else: # Left (default)
					attack_area.position.x = 12

		State.ATTACK_PURPLE:
			state_timer = attack_duration
			velocity = Vector2.ZERO
			purple_dealt_damage = false # Reset Purple damage flag
			if main_sprite:
				main_sprite.play("attackPurple")

			# Set AttackArea position based on current facing direction (consider scale 2)
			if attack_area and main_sprite:
				if main_sprite.flip_h: # Right (flipped)
					attack_area.position.x = -12
				else: # Left (default)
					attack_area.position.x = 12

		State.COOLDOWN:
			state_timer = attack_cooldown
			velocity = Vector2.ZERO
			if main_sprite:
				main_sprite.play("idle")

#endregion

#region Signal Callbacks

func _on_sprite_frame_changed():
	if not main_sprite or not attack_area:
		print("No sprite or attack_area")
		return

	var current_frame = main_sprite.frame
	var current_anim = main_sprite.animation
	print("Frame changed: ", current_anim, " - frame ", current_frame)

	# During Blue attack
	if current_state == State.ATTACK_BLUE and current_frame == blue_hit_frame:
		print("Blue attack hit frame! (frame ", blue_hit_frame, ")")
		if not blue_dealt_damage:
			check_attack_hit()
			blue_dealt_damage = true
			print("Blue damage processed")
		else:
			print("Blue damage already processed")

	# During Purple attack
	elif current_state == State.ATTACK_PURPLE and current_frame == purple_hit_frame:
		print("Purple attack hit frame! (frame ", purple_hit_frame, ")")
		if not purple_dealt_damage:
			check_attack_hit()
			purple_dealt_damage = true
			print("Purple damage processed")
		else:
			print("Purple damage already processed")

func check_attack_hit():
	if not attack_area:
		print("No attack_area!")
		return

	# Check player info
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player global position: ", player.global_position)
		print("Player collision_layer: ", player.collision_layer)
		print("Player collision_mask: ", player.collision_mask)
		var distance = attack_area.global_position.distance_to(player.global_position)
		print("Distance between AttackArea and player: ", distance)
	else:
		print("Cannot find player!")

	print("AttackArea global position: ", attack_area.global_position)
	print("AttackArea local position: ", attack_area.position)
	print("AttackArea collision_mask: ", attack_area.collision_mask)
	print("AttackArea monitoring: ", attack_area.monitoring)
	print("Boss flip_h: ", main_sprite.flip_h if main_sprite else "No sprite")

	# Check CollisionShape2D
	var collision_shape = attack_area.get_node_or_null("CollisionShape2D")
	if collision_shape:
		print("CollisionShape2D disabled: ", collision_shape.disabled)
		print("CollisionShape2D shape: ", collision_shape.shape)
	else:
		print("Cannot find CollisionShape2D!")

	var overlapping_bodies = attack_area.get_overlapping_bodies()
	print("Overlapping body count: ", overlapping_bodies.size())

	for body in overlapping_bodies:
		print("Found body: ", body.name, ", groups: ", body.get_groups())
		if body.is_in_group("player"):
			print("=== Player detected! Processing damage ===")
			if body.has_method("lose_life"):
				body.lose_life()
				print("Player lose_life() called")
			else:
				print("Player has no lose_life() method")
		else:
			print("Not in player group")

func _on_animation_finished():
	# Add extra handling here if needed when an animation finishes
	pass

#endregion

#region Enrage System

func check_enrage():
	# If already enraged, don't check
	if is_enraged:
		return

	# Trigger enrage when HP is at or below the threshold
	if current_health <= enrage_health_threshold:
		activate_enrage()

func activate_enrage():
	if is_enraged:
		return

	is_enraged = true

	# Increase movement speed
	move_speed = base_move_speed * enraged_move_speed_multiplier

	# Reduce attack cooldown (faster attacks)
	attack_cooldown = base_attack_cooldown * enraged_attack_cooldown_multiplier

	print("=== JungleBoss ENRAGE ACTIVATED! ===")
	print("Move speed: ", base_move_speed, " -> ", move_speed)
	print("Attack cooldown: ", base_attack_cooldown, " -> ", attack_cooldown)

	# Optional visual effect (e.g., change sprite color, particle effects, etc.)
	if main_sprite:
		# Add a red tint to visually indicate enraged state
		main_sprite.modulate = Color(1.5, 0.8, 0.8, 1.0)

#endregion
