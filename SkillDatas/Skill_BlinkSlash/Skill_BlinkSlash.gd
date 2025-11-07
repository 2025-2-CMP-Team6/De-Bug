# skills/blink_slash/Skill_BlinkSlash.gd
extends BaseSkill

# 스킬 고유의 속성들입니다.
@export var teleport_distance: float = 60.0
@export var safety_margin: float = 16.0
@export var slide_speed: float = 600.0
@export var slide_friction: float = 2000.0
@export var hitbox_width: float = 50.0
@export var slash_visual_texture: Texture # 디버그용 히트박스 시각화에 사용할 이미지입니다.

var is_sliding: bool = false
var slide_direction: Vector2 = Vector2.ZERO

func _init():
	# 이 스킬은 타겟 지정이 필수임을 설정합니다.
	requires_target = true
	
	# 이 스킬은 특정 조건(미끄러짐 종료)에 따라 시전이 끝남을 설정합니다.
	ends_on_condition = true


# 스킬의 핵심 로직을 실행합니다.
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target) # is_active = true로 설정됩니다.
	
	# player.gd에서 이미 타겟을 확인하지만, 안전을 위해 여기서 한 번 더 확인합니다.
	if target == null:
		is_active = false # 타겟이 없으면 스킬을 즉시 종료 상태로 만듭니다.
		return
	if not target.has_method("get_rid"):
		is_active = false # 유효한 노드가 아니면 스킬을 즉시 종료 상태로 만듭니다.
		return
	
	var start_pos = owner.global_position
	slide_direction = (target.global_position - start_pos).normalized()
	if slide_direction == Vector2.ZERO:
		slide_direction = Vector2.RIGHT
	
	# 타겟 뒤쪽으로 순간이동할 위치를 계산합니다. (벽 관통 방지)
	var ray_from = target.global_position
	var ray_to = ray_from + (slide_direction * teleport_distance)
	var space_state = owner.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = [owner.get_rid(), target.get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	
	var target_position
	if result:
		target_position = result.position - (slide_direction * safety_margin)
	else:
		target_position = ray_to
	
	# 계산된 위치로 플레이어를 순간이동시킵니다.
	owner.global_position = target_position
	
	# 이동 경로에 있는 적들에게 데미지를 줍니다.
	apply_slash_damage(start_pos, target_position, owner)
	
	# 순간이동 후 짧게 미끄러지는 효과를 위해 초기 속도를 설정합니다.
	owner.velocity = slide_direction * slide_speed
	is_sliding = true


# 지정된 경로에 사각형 형태의 히트박스를 생성하여 적들에게 데미지를 입힙니다.
func apply_slash_damage(start_pos: Vector2, end_pos: Vector2, owner: CharacterBody2D):
	var length = start_pos.distance_to(end_pos)
	var space_state = owner.get_world_2d().direct_space_state
	var shape = RectangleShape2D.new()
	shape.size = Vector2(hitbox_width, length)
	
	var angle = (end_pos - start_pos).angle() + deg_to_rad(90)
	var center_pos = (start_pos + end_pos) / 2
	var xform = Transform2D(angle, center_pos)

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [owner.get_rid()]
	
	# 디버깅을 위해 히트박스 영역을 이미지로 표시합니다.
	_debug_draw_hitbox(shape, xform, owner)

	var results: Array = space_state.intersect_shape(query)
	
	var did_hit_enemy: bool = false
	
	var hit_enemies = []
	for res in results:
		var collider = res.collider
		if collider.is_in_group("enemies") and not collider in hit_enemies:
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
				print("벽력일섬 히트: " + collider.name)
				hit_enemies.append(collider)
				did_hit_enemy = true

	# 적을 한 명이라도 타격했다면 화면 효과를 재생합니다.
	if did_hit_enemy:
		EffectManager.play_screen_shake(12.0, 0.15)
		EffectManager.play_multi_flash(Color.WHITE, 0.05, 3)

# 스킬 시전 중 매 물리 프레임마다 호출되어 미끄러짐 효과를 처리합니다.
func process_skill_physics(owner: CharacterBody2D, delta: float):
	# execute 함수에서 is_sliding이 true로 설정된 동안 이 로직이 실행됩니다.
	if is_sliding:
		# 마찰력을 적용하여 속도를 점차 줄입니다.
		owner.velocity = owner.velocity.move_toward(Vector2.ZERO, slide_friction * delta)
		
		# 속도가 0이 되면 미끄러짐을 멈추고, 스킬이 종료되었음을 알립니다.
		if owner.velocity == Vector2.ZERO:
			is_sliding = false
			is_active = false # player.gd가 상태를 변경할 수 있도록 is_active를 false로 설정합니다.

# 디버깅 목적으로 히트박스 영역을 Sprite2D를 사용해 시각적으로 표시합니다.
func _debug_draw_hitbox(shape: Shape2D, xform: Transform2D, owner: Node):
	# 이 시각화는 Godot 에디터의 '디버그 > 충돌 모양 보이기' 옵션과 무관하게 표시됩니다.
	var debug_sprite = Sprite2D.new()
	
	# 인스펙터에서 설정한 텍스처를 사용합니다.
	if slash_visual_texture:
		debug_sprite.texture = slash_visual_texture
	else:
		return # 텍스처가 없으면 표시하지 않습니다.
	
	# 텍스처의 크기에 맞춰 스프라이트의 스케일을 조절하여 히트박스 모양과 일치시킵니다.
	if debug_sprite.texture.get_width() > 0:
		debug_sprite.scale.x = shape.size.x / debug_sprite.texture.get_width()
		debug_sprite.scale.y = shape.size.y / debug_sprite.texture.get_height()

	# 반투명하게 만들어 게임 화면과 구분되도록 합니다.
	debug_sprite.modulate = Color(1, 1, 1, 0.5)
	
	# 히트박스와 동일한 위치, 회전, 크기를 적용합니다.
	debug_sprite.global_transform = xform
	
	owner.get_parent().add_child(debug_sprite)
	
	# 잠시 후 자동으로 사라지도록 타이머를 설정합니다.
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(debug_sprite.queue_free)