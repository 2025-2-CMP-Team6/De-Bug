# TutorialBoss.gd
extends BaseEnemy

#region 설정 변수
@export var move_speed: float = 80.0
@export var attack_range: float = 100.0  # 칼 공격 범위 (근접) - 조금 넓게
@export var chase_range: float = 400.0  # 추격 범위
@export var attack_cooldown: float = 2.0
@export var attack_duration: float = 0.6  # 공격 애니메이션 길이
@export var attack_hit_delay: float = 0.2  # 공격 시작 후 데미지 판정까지 딜레이

# 보스 상태 enum
enum State {
	IDLE,      # 대기/배회
	CHASE,     # 플레이어 추적
	ATTACK,    # 공격 중
	COOLDOWN   # 공격 후 쿨타임
}

# 상태 변수
var current_state: State = State.IDLE
var state_timer: float = 0.0  # 상태별 타이머
var patrol_direction: int = 1
var patrol_timer: float = 0.0
var has_dealt_damage: bool = false  # 현재 공격에서 데미지를 줬는지 여부
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

	# AttackArea 초기 설정 (항상 monitoring true로 유지)
	if attack_area:
		attack_area.monitoring = true
		print("AttackArea 초기 설정:")
		print("  - monitoring: ", attack_area.monitoring)
		print("  - collision_layer: ", attack_area.collision_layer)
		print("  - collision_mask: ", attack_area.collision_mask)

		# CollisionShape2D 확인
		var shape_count = 0
		for child in attack_area.get_children():
			if child is CollisionShape2D:
				shape_count += 1
				print("  - CollisionShape2D 있음, shape: ", child.shape != null)
		if shape_count == 0:
			print("  - 경고: CollisionShape2D가 없습니다!")

	# 시그널 연결
	if main_sprite and not main_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		main_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if main_sprite and not main_sprite.animation_finished.is_connected(_on_animation_finished):
		main_sprite.animation_finished.connect(_on_animation_finished)

	if attack_area and not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		print("AttackArea.body_entered 신호 연결됨")

	print("=== TutorialBoss _ready 완료 ===")

func _process_movement(delta):
	# 죽었으면 멈춤
	if current_health <= 0:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
		return

	# 상태 타이머 감소
	if state_timer > 0:
		state_timer -= delta

	# 플레이어 찾기
	var player = get_tree().get_first_node_in_group("player")

	# 상태별 행동
	match current_state:
		State.IDLE:
			handle_idle_state(delta, player)

		State.CHASE:
			handle_chase_state(delta, player)

		State.ATTACK:
			handle_attack_state(delta)

		State.COOLDOWN:
			handle_cooldown_state(delta, player)

	# 스프라이트 방향 전환 (플레이어 방향 보기)
	if main_sprite and velocity.x != 0:
		main_sprite.flip_h = (velocity.x < 0)

		# AttackArea 위치도 스프라이트 방향에 맞춰 조정
		if attack_area:
			if main_sprite.flip_h:  # 왼쪽을 보고 있으면
				attack_area.position = Vector2(-16.5, 7.25)
			else:  # 오른쪽을 보고 있으면
				attack_area.position = Vector2(16.5, 7.25)

# --- 상태별 처리 함수들 ---

func handle_idle_state(delta, player):
	if player:
		var distance = global_position.distance_to(player.global_position)

		# 플레이어가 추격 범위 안에 들어오면 추적 시작
		if distance <= chase_range:
			change_state(State.CHASE)
			return

	# 배회 행동
	patrol_behavior(delta)

func handle_chase_state(delta, player):
	if not player:
		change_state(State.IDLE)
		return

	var distance = global_position.distance_to(player.global_position)

	# 공격 범위 안에 들어오면 공격
	if distance <= attack_range:
		change_state(State.ATTACK)
		return

	# 추격 범위를 벗어나면 idle로 복귀
	if distance > chase_range:
		change_state(State.IDLE)
		return

	# 플레이어 추적
	chase_player(player)

func handle_attack_state(delta):
	# 공격 중에는 멈춤
	velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# 딜레이 후에만 데미지 체크 (칼 휘두르는 타이밍과 맞추기)
	var time_since_attack_start = attack_duration - state_timer
	var should_check_damage = time_since_attack_start >= attack_hit_delay

	# 아직 데미지를 주지 않았고, 딜레이가 지났다면 AttackArea에 플레이어가 있는지 확인
	if not has_dealt_damage and should_check_damage and attack_area:
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		print("[DEBUG] ATTACK 상태 (딜레이 후) - 경과 시간: ", time_since_attack_start,
			  ", has_dealt_damage: ", has_dealt_damage,
			  ", overlapping_bodies 수: ", overlapping_bodies.size(),
			  ", AttackArea pos: ", attack_area.position)

		for body in overlapping_bodies:
			print("[DEBUG] 겹친 body: ", body.name, ", is player?: ", body.is_in_group("player"))
			if body.is_in_group("player"):
				print("=== handle_attack_state: 플레이어 감지! 데미지 처리 ===")
				if body.has_method("lose_life"):
					body.lose_life()
					print("플레이어 lose_life() 호출됨")
					has_dealt_damage = true
					print("데미지 플래그 설정")
					break

	# 공격 애니메이션 시간이 끝나면 쿨타임 상태로 전환
	if state_timer <= 0:
		change_state(State.COOLDOWN)

func handle_cooldown_state(delta, player):
	# 쿨타임이 끝나면 추적 또는 idle 상태로
	if state_timer <= 0:
		if player and global_position.distance_to(player.global_position) <= chase_range:
			change_state(State.CHASE)
		else:
			change_state(State.IDLE)
		return

	# 쿨타임 중에는 천천히 플레이어 추적
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= chase_range:
			chase_player(player)
			velocity.x *= 0.5  # 속도 50%로 감소
		else:
			patrol_behavior(delta)
	else:
		patrol_behavior(delta)

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

# --- 상태 전환 ---

func change_state(new_state: State):
	if current_state == new_state:
		return

	print("TutorialBoss: 상태 변경 ", State.keys()[current_state], " -> ", State.keys()[new_state])

	# 새 상태 시작 처리
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
			has_dealt_damage = false  # 새 공격 시작 시 데미지 플래그 리셋
			if main_sprite:
				main_sprite.play("attack")

			# AttackArea 위치를 현재 보는 방향에 맞춰 설정
			if attack_area and main_sprite:
				if main_sprite.flip_h:  # 왼쪽을 보고 있으면
					attack_area.position = Vector2(-16.5, 7.25)
				else:  # 오른쪽을 보고 있으면
					attack_area.position = Vector2(16.5, 7.25)

			print("[DEBUG] ===== ATTACK 상태 시작 =====")
			print("[DEBUG] has_dealt_damage 리셋: ", has_dealt_damage)
			print("[DEBUG] main_sprite.flip_h: ", main_sprite.flip_h if main_sprite else "N/A")
			print("[DEBUG] attack_area 존재: ", attack_area != null)
			if attack_area:
				print("[DEBUG] attack_area.monitoring: ", attack_area.monitoring)
				print("[DEBUG] attack_area.position: ", attack_area.position)

		State.COOLDOWN:
			state_timer = attack_cooldown
			if main_sprite:
				main_sprite.play("idle")
			print("TutorialBoss: 쿨타임 시작 (", attack_cooldown, "초)")

# --- 공격 시퀀스 (더 이상 사용하지 않음, change_state로 대체) ---

# 공격 애니메이션의 특정 프레임에서 히트박스 활성화 (더 이상 사용하지 않음)
func _on_sprite_frame_changed():
	pass

# 공격 애니메이션이 끝났을 때 (참고용으로 남겨둠, 필요시 활용 가능)
func _on_animation_finished():
	# 타이머 기반으로 상태 전환을 처리하므로 이 시그널은 사용하지 않음
	pass

# --- 충돌 처리 ---

# 칼 공격이 플레이어에게 닿았을 때
func _on_attack_area_body_entered(body):
	# ATTACK 상태가 아니거나 이미 데미지를 줬으면 무시
	if current_state != State.ATTACK or has_dealt_damage:
		return

	print("AttackArea 충돌 감지: ", body.name, ", 플레이어 그룹: ", body.is_in_group("player"))

	if body.is_in_group("player"):
		print("=== TutorialBoss의 칼이 플레이어 적중! ===")
		if body.has_method("lose_life"):
			body.lose_life()
			print("플레이어 lose_life() 호출됨")
			has_dealt_damage = true  # 데미지를 줬다고 표시
			print("데미지 플래그 설정 (이번 공격에서 더 이상 데미지 없음)")
		else:
			print("경고: 플레이어에게 lose_life() 메소드가 없습니다!")
