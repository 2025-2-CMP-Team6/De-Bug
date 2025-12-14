# boss_virus.gd
extends BaseEnemy

#region Boss-Specific Settings
@export var attack_interval_min: float = 2.0
@export var attack_interval_max: float = 4.0
#endregion

#region Node References
@export var pattern_timer: Timer
@export var teleport_timer: Timer
@export var sfx_player: AudioStreamPlayer
#endregion

#region Sound Assets
@export var sfx_tp: AudioStream      # 텔레포트 소리
@export var sfx_spiral: AudioStream  # 나선 탄막 발사 소리
@export var sfx_shoot: AudioStream   # 조준 사격 소리
#endregion

#region Projectiles
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
#endregion

#region State
var patterns = [1, 2, 3]
var player: Node2D

enum State {
	IDLE,
	PATTERN
}
#endregion

func _ready():
	super._ready()
	player = get_tree().get_first_node_in_group("player")
	process_mode = Node.PROCESS_MODE_ALWAYS

	if pattern_timer:
		pattern_timer.timeout.connect(_on_pattern_timer_timeout)
	if teleport_timer:
		teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	
	start_attack_pattern()

func _physics_process(delta: float):
	pass

# Boss patterns
func start_attack_pattern():
	if pattern_timer:
		pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
		pattern_timer.start()

func _on_pattern_timer_timeout():
	spawn_random_pattern()

func spawn_random_pattern():
	print("Boss Pattern Activated")
	var chosen_pattern = patterns.pick_random()
	match chosen_pattern:
		1: boss_tp()
		2: boss_spiral_shot()
		_: boss_shot()


func boss_tp():
	
	if sfx_player and sfx_tp:
		sfx_player.stream = sfx_tp
		sfx_player.volume_db = 8.0
		sfx_player.pitch_scale = 1.0
		sfx_player.play()
		
	position.x = -5000
	teleport_timer.wait_time = 1.0
	teleport_timer.start()

func _on_teleport_timer_timeout():
	position.x = randi_range(-1200, 1200)
	# After teleport ends, start the next pattern timer
	pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
	pattern_timer.start()

func boss_spiral_shot():
	var num_shots = 5
	var interval = 0.3
	
	for i in range(num_shots):
		
		if sfx_player and sfx_spiral:
			sfx_player.stream = sfx_spiral
			sfx_player.volume_db = 0.0
			sfx_player.pitch_scale = randf_range(0.9, 1.1)
			sfx_player.play()
			
		var num_bullets = 8
		var angle_step = TAU / num_bullets
		var angle_offset = (TAU / num_bullets) * i * 0.2

		for j in range(num_bullets):
			var angle = j * angle_step + angle_offset
			var direction = Vector2.RIGHT.rotated(angle)
			var bullet = BULLET_SCENE.instantiate()
			bullet.direction = direction
			bullet.global_position = global_position
			get_parent().add_child(bullet)
		
		await get_tree().create_timer(interval).timeout
		if not is_instance_valid(self):
			return
	
	# After the pattern ends, start the next pattern timer
	pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
	pattern_timer.start()

func boss_shot():
	if not is_instance_valid(player):
		return
	var interval = 0.3
	for i in range(8):
		
		if sfx_player and sfx_shoot:
			sfx_player.stream = sfx_shoot
			sfx_player.volume_db = 0.0
			sfx_player.pitch_scale = randf_range(0.9, 1.1)
			sfx_player.play()
			
		var bullet = BULLET_SCENE.instantiate()
		bullet.direction = (player.global_position - global_position).normalized()
		bullet.speed = 600.0
		bullet.global_position = global_position
		get_parent().add_child(bullet)
		await get_tree().create_timer(interval).timeout
		if not is_instance_valid(self):
			return
	
	pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
	pattern_timer.start()

func _get_item_rect() -> Rect2:
	return Rect2(-50000, -50000, 100000, 100000)
