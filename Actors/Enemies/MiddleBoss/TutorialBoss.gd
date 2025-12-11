# TutorialBoss.gd
extends BaseEnemy

#region 설정 변수
@export var move_speed: float = 80.0
@export var attack_range: float = 100.0  # 칼 공격 범위 (근접) - 조금 넓게
@export var chase_range: float = 400.0  # 추격 범위
@export var attack_cooldown: float = 2.0

# 상태 변수
var is_attacking: bool = false
var on_cooldown: bool = false
var patrol_direction: int = 1
var patrol_timer: float = 0.0
#endregion

#region 노드 참조
# 현재 씬 구조에 맞게 수정
@onready var main_sprite = $AnimatedSprite2D  # Visuals 없이 직접 자식
@onready var attack_area = get_node_or_null("AttackArea")  # 칼의 히트박스 (추가 필요)
#endregion

func _ready():
	super._ready()

	# enemies 그룹에 추가 (스킬 타겟팅을 위해 필수!)
	add_to_group("enemies")

	# 디버깅: 노드 확인
	print("=== TutorialBoss _ready 시작 ===")
	print("enemies 그룹 추가됨: ", is_in_group("enemies"))
	print("main_sprite 찾음: ", main_sprite != null)
	if main_sprite:
		print("sprite_frames 있음: ", main_sprite.sprite_frames != null)
		# 초기 애니메이션 강제 재생
		main_sprite.play("idle")
		print("idle 애니메이션 재생 시작")

	print("attack_area 찾음: ", attack_area != null)

	# 공격 판정 초기 비활성화
	if attack_area:
		attack_area.monitoring = false

	# 시그널 연결
	if main_sprite and not main_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if main_sprite and not main_sprite.animation_finished.is_connected(_on_animation_finished):
		main_sprite.animation_finished.connect(_on_animation_finished)

	if attack_area and not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	print("=== TutorialBoss _ready 완료 ===")

func _process_movement(delta):
	# 공격 중이거나 죽었으면 멈춤
	if is_attacking or current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# 쿨타임 중 멈춤
	if on_cooldown:
		velocity.x = move_toward(velocity.x, 0, 100 * delta)
		if main_sprite:
			main_sprite.play("idle")
		return

	# 플레이어 찾기
	var player = get_tree().get_first_node_in_group("player")

	if player:
		var distance = global_position.distance_to(player.global_position)

		# [상황 1] 공격 범위 안 -> 공격 시작
		if distance <= attack_range:
			print("플레이어 거리: ", distance, " / 공격 범위: ", attack_range, " -> 공격!")
			start_attack()

		# [상황 2] 추격 범위 안 -> 플레이어 추적
		elif distance <= chase_range:
			chase_player(player)

		# [상황 3] 멀면 배회
		else:
			patrol_behavior(delta)
	else:
		patrol_behavior(delta)

	# 스프라이트 방향 전환 (플레이어 방향 보기)
	if main_sprite and velocity.x != 0:
		main_sprite.flip_h = (velocity.x < 0)

# --- 행동 패턴 함수들 ---

func chase_player(player):
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * move_speed
	if main_sprite:
		main_sprite.play("move")

func patrol_behavior(delta):
	patrol_timer -= delta

	# 1~2초마다 행동 변경
	if patrol_timer <= 0:
		patrol_timer = randf_range(1.0, 2.0)
		var random_choice = randi() % 5

		# 40% 확률로 멈춤
		if random_choice <= 1:
			patrol_direction = 0
		elif random_choice == 2:
			patrol_direction = 1
		elif random_choice == 3:
			patrol_direction = -1
		else:
			patrol_direction = -patrol_direction

	velocity.x = patrol_direction * (move_speed * 0.5)

	if main_sprite:
		if velocity.x == 0:
			main_sprite.play("idle")
		else:
			main_sprite.play("move")

# --- 공격 시퀀스 ---

func start_attack():
	if is_attacking or on_cooldown:
		print("공격 불가: is_attacking=", is_attacking, ", on_cooldown=", on_cooldown)
		return

	print("=== TutorialBoss: 공격 시작! ===")
	is_attacking = true
	on_cooldown = true
	velocity = Vector2.ZERO  # 공격 중 이동 정지

	if main_sprite:
		main_sprite.play("attack")
		print("attack 애니메이션 재생")

	# AttackArea가 있으면 활성화 (단순화: 공격 중에는 계속 활성화)
	if attack_area:
		attack_area.monitoring = true
		print("AttackArea 활성화됨")
	else:
		print("경고: AttackArea가 없습니다!")

# 공격 애니메이션의 특정 프레임에서 히트박스 활성화 (더 이상 사용하지 않음 - 단순화)
func _on_sprite_frame_changed():
	# 공격 중에는 계속 활성화되도록 단순화
	pass

# 공격 애니메이션이 끝났을 때
func _on_animation_finished():
	if not main_sprite:
		return

	if main_sprite.animation == "attack":
		print("=== attack 애니메이션 종료 ===")
		# 공격 종료
		is_attacking = false
		if attack_area:
			attack_area.monitoring = false
			print("AttackArea 비활성화됨")

		main_sprite.play("idle")

		# 쿨타임 시작
		print("TutorialBoss: 쿨타임 시작 (", attack_cooldown, "초)")
		await get_tree().create_timer(attack_cooldown).timeout
		on_cooldown = false
		print("TutorialBoss: 쿨타임 종료, 다시 공격 가능")

# --- 충돌 처리 ---

# 칼 공격이 플레이어에게 닿았을 때
func _on_attack_area_body_entered(body):
	print("AttackArea 충돌 감지: ", body.name, ", 플레이어 그룹: ", body.is_in_group("player"))

	if body.is_in_group("player"):
		print("=== TutorialBoss의 칼이 플레이어 적중! ===")
		if body.has_method("lose_life"):
			body.lose_life()
			print("플레이어 lose_life() 호출됨")
		else:
			print("경고: 플레이어에게 lose_life() 메소드가 없습니다!")

		# 한 번만 맞게 하려면 즉시 비활성화
		if attack_area:
			attack_area.monitoring = false
			print("공격 성공 후 AttackArea 비활성화")
