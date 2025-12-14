# fly_boss.gd
# owner: 김동현
class_name MidBossHover extends BaseEnemy

#region State Definition
enum MeteoState {
	NORMAL,
	TO_START_POS,
	BOMBING_RUN
}
var current_state: MeteoState = MeteoState.NORMAL
var detected_player: bool = false
#endregion

#region Configuration
@export_group("Movement")
@export var fly_speed: float = 400.0
@export var acceleration: float = 5.0
@export var erratic_intensity: float = 3.0
@export var preferred_range: float = 600.0

@export_group("Combat")
# shoot
@export var shoot_interval: float = 2.0
@export var bullet_speed: float = 1200.0
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
# summon
@export var summon_cooldown: float = 5.0
@export var summon_count: int = 2
@export var summon_speed: float = 400.0
@export var minion_scene: PackedScene
# orbital
@export var orbital_count: int = 5
@export var orbital_radius: float = 320.0
@export var orbital_duration: float = 4.0
@export var orbital_speed: float = 350.0
@export var orbital_shoot_speed: float = 6.0

# bombing
@export_group("Bombing Pattern")
@export var meteor_scene: PackedScene
@export var bombing_start_x: float
@export var bombing_end_x: float
@export var bombing_speed: float = 600.0
@export var bomb_interval_min: float = 0.5
@export var bomb_interval_max: float = 1.0
@export var bombing_range: float = 1000.0
#endregion

#region Internal Variables
var player: Node2D = null
var creating: bool = false

var target_velocity: Vector2 = Vector2.ZERO
var move_change_timer: float = 0.0

var orbitals = []
var orbital_active_timer: float = 0.0
var current_orbit_angle: float = 0.0

# Bombing variables
var bomb_drop_timer: float = 0.0
var bombing_y: float = 0.0
var is_firing_orbitals: bool = false
#endregion

#region Node References
@onready var animation = $Visuals/AnimatedSprite2D
@onready var pattern = $PatternTimer
#endregion

func _ready():
	super._ready()
	gravity = 0.0
	is_boss = true
	
	if animation:
		animation.play("idle")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	_pick_new_direction()
	
	pattern.timeout.connect(_handle_combat)
	_start_pattern_timer()

func _process_movement(delta):
	if not is_instance_valid(player) or current_health <= 0:
		velocity = velocity.lerp(Vector2.ZERO, 2.0 * delta)
		return

	if not detected_player:
		if global_position.distance_to(player.global_position) <= 500.0:
			detected_player = true
			_start_pattern_timer()
		else:
			_apply_erratic_movement(delta)
			return

	_process_orbitals(delta)

	match current_state:
		MeteoState.NORMAL:
			if not creating:
				_apply_erratic_movement(delta)
				
		MeteoState.TO_START_POS:
			_process_to_start_pos()
			
		MeteoState.BOMBING_RUN:
			_process_bombing_run(delta)

#region Movement Logic
func _apply_erratic_movement(delta):
	move_change_timer -= delta
	
	if move_change_timer <= 0:
		_pick_new_direction()
	
	velocity = velocity.lerp(target_velocity, acceleration * delta)
	
	# Direction change
	if animation:
		animation.flip_h = (player.global_position.x < global_position.x)

func _pick_new_direction():
	move_change_timer = randf_range(0.1, 0.2)
	
	if not is_instance_valid(player): return

	var dist = global_position.distance_to(player.global_position)
	var dir_to_player = (player.global_position - global_position).normalized()
	
	var base_velocity = Vector2.ZERO
	
	if dist > preferred_range + 150.0:
		base_velocity = dir_to_player * fly_speed
	elif dist < preferred_range - 150.0:
		base_velocity = - dir_to_player * (fly_speed * 1.2)
	else:
		var strafe_dir = Vector2(-dir_to_player.y, dir_to_player.x)
		if randf() > 0.5: strafe_dir = - strafe_dir
		base_velocity = strafe_dir * (fly_speed * 0.8)

	var jitter = Vector2(randf() - 0.5, randf() - 0.5) * fly_speed * erratic_intensity
	target_velocity = base_velocity + jitter
#endregion

#region Combat Pattern Branch
func _start_pattern_timer():
	pattern.wait_time = randf_range(2.0, 4.0)
	pattern.start()

func _handle_combat():
	if current_state != MeteoState.NORMAL: return
	if not detected_player: return

	var pattern_choice = randi_range(1, 8)
	print("Pattern Selected: ", pattern_choice)
	
	match pattern_choice:
		1, 2, 3: shoot_spread_attack()
		4: summon_minions()
		5, 6: start_orbital_pattern()
		7, 8: start_bombing_pattern()
	
		
#endregion

#region
# shoot pattern
func shoot_spread_attack():
	if not is_instance_valid(player): return
	var base_dir = (player.global_position - global_position).normalized()
	var angles = [-0.2, 0.0, 0.2]
	for angle in angles:
		var bullet = BULLET_SCENE.instantiate()
		var final_dir = base_dir.rotated(angle)
		if projectile_texture: bullet.custom_texture = projectile_texture
		bullet.global_position = global_position
		bullet.direction = final_dir
		bullet.speed = bullet_speed
		get_tree().current_scene.add_child(bullet)
	_start_pattern_timer()
# summon pattern
func summon_minions():
	if not minion_scene:
		print("Warning: Minion Scene is empty")
		return
	creating = true
	await get_tree().create_timer(0.5).timeout
	var spacing = 80.0
	for i in range(summon_count):
		var x_offset = (i - (summon_count - 1) / 2.0) * spacing
		var minion = minion_scene.instantiate()
		minion.global_position = global_position + Vector2(x_offset, 40)
		get_tree().current_scene.add_child(minion)
		minion.velocity = Vector2(x_offset, 0).normalized() * summon_speed
	creating = false
	_start_pattern_timer()

#region orbital pattern
func start_orbital_pattern():
	if orbitals.size() > 0: return
	orbital_active_timer = orbital_duration
	for i in range(orbital_count):
		var bullet = BULLET_SCENE.instantiate()
		bullet.speed = 0.0
		if "damage" in bullet: bullet.damage = 10.0
		if projectile_texture: bullet.custom_texture = projectile_texture
		if bullet.has_node("LifeTimer"):
			bullet.get_node("LifeTimer").wait_time = 8.0
			bullet.get_node("LifeTimer").start()
		get_tree().current_scene.add_child(bullet)
		var angle_offset = (TAU / orbital_count) * i
		orbitals.append({"node": bullet, "offset": angle_offset})

func _process_orbitals(delta):
	if orbitals.size() == 0:
		if is_firing_orbitals:
			is_firing_orbitals = false
			_start_pattern_timer()
		return

	current_orbit_angle += 5.0 * delta
	
	var fire_target_vector = Vector2.ZERO
	if is_firing_orbitals:
		if not is_instance_valid(player):
			orbitals.clear()
			is_firing_orbitals = false
			_start_pattern_timer()
			return
		
		if player.global_position.x < global_position.x:
			fire_target_vector = Vector2.DOWN
		else:
			fire_target_vector = Vector2.UP

	# Iterate in reverse order to prevent index errors when deleting from list and ensure stability
	for i in range(orbitals.size() - 1, -1, -1):
		var data = orbitals[i]
		var bullet = data["node"]
		
		if not is_instance_valid(bullet):
			orbitals.remove_at(i)
			continue
			
		var angle_offset = data["offset"]
		var angle = current_orbit_angle + angle_offset
		var orbit_vec = Vector2(cos(angle), sin(angle))
		var target_pos = global_position + orbit_vec * orbital_radius
		bullet.global_position = target_pos
		
		if is_firing_orbitals:
			if orbit_vec.dot(fire_target_vector) > 0.95:
				var dir = (player.global_position - bullet.global_position).normalized()
				bullet.direction = dir
				bullet.speed = orbital_shoot_speed * orbital_speed
				orbitals.remove_at(i) # Remove fired bullet from list
	
	if not is_firing_orbitals:
		orbital_active_timer -= delta
		if orbital_active_timer <= 0: launch_orbitals()

func launch_orbitals():
	if not is_instance_valid(player):
		orbitals.clear()
		_start_pattern_timer()
		return
	
	is_firing_orbitals = true
#endregion

#region bombing pattern
func start_bombing_pattern():
	print("Mid Boss: Preparing aerial bombing!")
	bombing_start_x = player.global_position.x - bombing_range
	bombing_end_x = player.global_position.x + bombing_range
	bombing_y = player.global_position.y - 1200.0
	current_state = MeteoState.TO_START_POS
	
	if animation: animation.flip_h = false

func _process_to_start_pos():
	var dir = Vector2((bombing_start_x - global_position.x), (bombing_y - global_position.y)).normalized()
	velocity = dir * (fly_speed * 2.0)
	if global_position.distance_to(Vector2(bombing_start_x, bombing_y)) < 20.0:
		print("Mid Boss: Starting bombing!")
		current_state = MeteoState.BOMBING_RUN
		bomb_drop_timer = 0.0
		velocity = Vector2.ZERO

func _process_bombing_run(delta):
	velocity = Vector2(bombing_speed, 0)
	
	bomb_drop_timer -= delta
	if bomb_drop_timer <= 0:
		spawn_one_meteor_at_self()
		bomb_drop_timer = randf_range(bomb_interval_min, bomb_interval_max)
	
	if global_position.x >= bombing_end_x:
		print("Mid Boss: Bombing finished, returning")
		current_state = MeteoState.NORMAL
		_start_pattern_timer()

func spawn_one_meteor_at_self():
	if not meteor_scene: return
	
	var meteor = meteor_scene.instantiate()
	
	meteor.global_position = global_position + Vector2(0, 50)
	
	get_tree().current_scene.add_child(meteor)
#endregion


#endregion


func get_camera_bounds(camera: Camera2D) -> Rect2:
	var center = camera.get_screen_center_position()
	var visible_size = get_viewport_rect().size / camera.zoom
	var top_left = center - (visible_size / 2)
		
	return Rect2(top_left, visible_size)
