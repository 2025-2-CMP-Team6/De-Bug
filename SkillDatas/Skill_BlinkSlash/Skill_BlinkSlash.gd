# skills/blink_slash/Skill_BlinkSlash.gd
extends BaseSkill

# --- 기존 변수 ---
@export var teleport_distance: float = 60.0 # 적 뒤로 이동할 '최대' 거리
@export var safety_margin: float = 16.0

# --- 미끄러짐 효과를 위한 새 변수 ---
@export var slide_speed: float = 600.0 # 텔레포트 직후 미끄러지기 시작하는 속도
@export var slide_friction: float = 2000.0 # 마찰력 (초당 감속되는 속도, 클수록 빨리 멈춤)

## ★ (추가) 히트박스의 폭 (직선의 두께)
@export var hitbox_width: float = 50.0


# 스킬의 현재 상태 (순간이동은 1프레임, 미끄러지는 건 여러 프레임)
var is_sliding: bool = false
var slide_direction: Vector2 = Vector2.ZERO # 미끄러질 방향 저장

# "스킬 발사!" 함수 (순간이동 + 미끄러짐 '시작')
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target)
	
	# 1. (수정) 타겟 유효성 검사
	if target == null:
		print("벽력일섬 타겟 없음! 스킬 발동 실패.")
		is_active = false # "나 끝났음" 신호를 바로 보냄
		return
	if not target.has_method("get_rid"):
		print("타겟이 물리 객체가 아님! 스킬 발동 실패.")
		is_active = false
		return
	
	# 2. ★ (추가) 히트박스 판정 및 데미지 적용
	#    (텔레포트보다 먼저 실행)
	apply_slash_damage(owner, target)
	
	# 3. (기존) 방향 벡터 계산
	slide_direction = (target.global_position - owner.global_position).normalized()
	
	if slide_direction == Vector2.ZERO:
		slide_direction = Vector2.RIGHT # 기본 방향

	# 2. 레이저 쏠 '시작점'과 '끝점' 계산
	var ray_from = target.global_position
	var ray_to = ray_from + (slide_direction * teleport_distance)
	
	# 3. 물리 엔진 공간(space state) 가져오기
	var space_state = owner.get_world_2d().direct_space_state
	
	# 4. 레이저 쿼리 파라미터 생성
	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = [owner.get_rid(), target.get_rid()]
	
	# 5. 레이저 발사!
	var result: Dictionary = space_state.intersect_ray(query)

	var target_position # 최종 이동할 위치

	if result:
		# 6-A. (충돌함)
		target_position = result.position - (slide_direction * safety_margin)
	else:
		# 6-B. (충돌 안함)
		target_position = ray_to
	
	# 5. (기존) 순간이동 및 미끄러짐 시작
	owner.global_position = target_position
	owner.velocity = slide_direction * slide_speed
	is_sliding = true


## ★ (추가) 벽력일섬 히트박스 판정 함수
func apply_slash_damage(owner: CharacterBody2D, target_enemy: Node2D):
	var start_pos = owner.global_position
	var end_pos = target_enemy.global_position
	var length = start_pos.distance_to(end_pos)
	
	# 1. 물리 엔진 공간 가져오기
	var space_state = owner.get_world_2d().direct_space_state
	
	# 2. 히트박스로 사용할 직사각형(Rectangle) Shape 생성
	var shape = RectangleShape2D.new()
	# (Shape의 길이는 y축 기준이므로, y에 길이를, x에 폭을 줍니다)
	shape.size = Vector2(hitbox_width, length)
	
	# 3. Shape의 위치와 회전을 설정할 Transform 생성
	var xform = Transform2D()
	xform.origin = (start_pos + end_pos) / 2 # 중심점
	# (Shape의 y축을 (end_pos - start_pos) 방향으로 정렬)
	xform = xform.rotated((end_pos - start_pos).angle() + deg_to_rad(90))
	
	# 4. 물리 쿼리 생성
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform
	query.collision_mask = owner.get_collision_mask() # 플레이어가 충돌하는 레이어와 동일하게
	query.collide_with_areas = true # Area2D (적) 포함
	query.collide_with_bodies = true # CharacterBody2D (적) 포함
	
	# 5. 쿼리 실행! (영역과 교차하는 모든 오브젝트를 반환)
	var results: Array = space_state.intersect_shape(query)
	
	# 6. 결과 분석 및 데미지 적용
	var hit_enemies = [] # 중복 데미지 방지 리스트
	for res in results:
		var collider = res.collider
		
		# "enemies" 그룹에 속하고, 아직 안 때렸고, take_damage 함수가 있다면
		if collider.is_in_group("enemies") and not collider in hit_enemies:
			if collider.has_method("take_damage"):
				# BaseSkill에서 물려받은 'damage' 변수 사용
				collider.take_damage(damage)
				print("벽력일섬 히트: " + collider.name)
				hit_enemies.append(collider) # 중복 방지 리스트에 추가

# "스킬 시전 중 물리 처리" 함수 (미끄러짐 '감속' 담당)
func process_skill_physics(owner: CharacterBody2D, delta: float):
	# is_sliding 플래그를 통해 스킬이 "미끄러지는 중"인지 확인
	if is_sliding:
		# 1. 마찰력을 적용하여 속도를 0으로 점차 줄임
		owner.velocity = owner.velocity.move_toward(Vector2.ZERO, slide_friction * delta)
		if owner.velocity.length() < 10.0:
			owner.velocity = Vector2.ZERO
			is_sliding = false
			is_active = false # "나 끝났음"
		
		# 2. 속도가 거의 0이 되었는지 확인
		elif owner.velocity.length() < 10.0:
			owner.velocity = Vector2.ZERO
			is_sliding = false # 미끄러짐 종료
			is_active = false # 스킬 종료
			
	else:
		# 미끄러짐이 끝난 후에는 속도를 0으로 유지
		owner.velocity = Vector2.ZERO
