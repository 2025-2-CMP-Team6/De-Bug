# Boss.gd
extends BaseEnemy

#region 보스 전용 설정
@export var attack_interval_min: float = 2.0
@export var attack_interval_max: float = 4.0
#endregion

#region 노드 참조
@export var pattern_timer: Timer
@export var teleport_timer: Timer
#endregion

#region 투사체
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
#endregion

#region 상태
var patterns = [1, 2, 3]

enum State {
	IDLE,
	PATTERN
}
#endregion

func _ready():
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 타이머 시그널 연결
	if pattern_timer:
		pattern_timer.timeout.connect(_on_pattern_timer_timeout)
	if teleport_timer:
		teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	
	# 보스 패턴 시작
	start_attack_pattern()

# 물리 로직 오버라이드
func _physics_process(delta: float):
	pass

# 보스 패턴
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
		_:
			print("No pattern executed")
			# 만약 실행할 패턴이 없으면 타이머를 다시 시작
			pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
			pattern_timer.start()


func boss_tp():
	position.x = -5000
	teleport_timer.wait_time = 1.0
	teleport_timer.start()

func boss_spiral_shot():
	var num_shots = 5
	var interval = 0.3
	for i in range(num_shots):
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
	
	# 패턴이 끝나면 다음 패턴 타이머 시작
	pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
	pattern_timer.start()

func _on_teleport_timer_timeout():
	position.x = randi_range(-1200, 1200)
	# 텔레포트가 끝나면 다음 패턴 타이머 시작
	pattern_timer.wait_time = randf_range(attack_interval_min, attack_interval_max)
	pattern_timer.start()
	
func _get_item_rect() -> Rect2:
	return Rect2(-50000, -50000, 100000, 100000)