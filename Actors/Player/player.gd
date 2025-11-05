extends CharacterBody2D

const BaseSkill = preload("res://SkillDatas/BaseSkill.gd")

# 플레이어 이동 관련 변수입니다.
@export var max_speed: float = 1000.0
@export var acceleration: float = 4000.0
@export var friction: float = 2000.0

# 플레이어 대시 관련 변수입니다.
@export var dash_speed: float = 3000.0
@export var dash_friction: float = 10000.0
@export var dash_duration: float = 0.02
@export var dash_cooldown: float = 0.8

# 플레이어 체력(잔기) 관련 변수입니다.
@export var max_lives: int = 3
@export var life_icon: Texture
@export var i_frames_duration: float = 1.0

# 플레이어 스태미나 관련 변수입니다.
@export var max_stamina: float = 100.0
@export var dash_cost: float = 35.0
@export var stamina_regen_rate: float = 20.0

# -------------------------------------------------------------------
# 상태 머신
# -------------------------------------------------------------------
enum State {
	IDLE,
	MOVE,
	MOVE_TO_IDLE,
	DASH,
	DASH_TO_IDLE,
	SKILL_CASTING
}

# 상태 관리에 사용되는 변수들입니다.
var current_state = State.IDLE
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var current_stamina: float = 0.0
var current_casting_skill: BaseSkill = null
var current_cast_target: Node2D = null
var is_invincible: bool = false
var current_lives: int = 0
var is_input_locked: bool = false # UI가 열렸을 때와 같이 플레이어의 입력을 제한할지 여부를 결정합니다.

# -------------------------------------------------------------------
# 노드 캐시
# -------------------------------------------------------------------
# 자주 사용하는 노드들을 미리 변수에 할당해 둡니다.
@onready var duration_timer = $DashDurationTimer
@onready var cooldown_timer = $DashCooldownTimer
@onready var skill_cast_timer = $SkillCastTimer

# UI
@onready var state_label = $StateDebugLabel
@onready var stamina_bar = $StaminaBar
@onready var visuals = $Visuals
@onready var skill_ui = get_parent().find_child("SkillUI")
@onready var lives_container = $HUD/LivesContainer
@onready var i_frames_timer = $IFramesTimer

# 스킬 슬롯
@onready var skill_1_slot = $Visuals/Skill1Slot
@onready var skill_2_slot = $Visuals/Skill2Slot
@onready var skill_3_slot = $Visuals/Skill3Slot
# -------------------------------------------------------------------
# 디버그 설정
#tool
var show_range: bool = true

func _draw():
	if show_range and skill_1_slot.get_child_count() > 0:
		var skill = skill_1_slot.get_child(0)
		if is_instance_valid(skill):
			if "max_cast_range" in skill and skill.max_cast_range > 0:
				draw_circle(Vector2.ZERO, skill.max_cast_range, Color(1, 0, 0, 0.3))


func _ready():
	duration_timer.timeout.connect(_on_dash_duration_timeout)
	cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	i_frames_timer.timeout.connect(_on_i_frames_timeout)
	skill_cast_timer.timeout.connect(_on_skill_cast_timeout)
	
	current_stamina = max_stamina
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina

	current_lives = max_lives
	update_lives_ui()
	
	equip_skill("res://SkillDatas/Skill_BlinkSlash/Skill_BlinkSlash.tscn", 1)
	equip_skill("res://SkillDatas/Skill_Melee/Skill_Melee.tscn", 2)
	equip_skill("res://SkillDatas/Skill_Parry/Skill_Parry.tscn", 3)
	
	change_state(State.IDLE)


func _physics_process(delta: float):
	var mouse_x = get_global_mouse_position().x
	var player_x = global_position.x
	
	if is_invincible:
		visuals.visible = (int(Time.get_ticks_msec() / 100) % 2) == 0
	else:
		visuals.visible = true

	if mouse_x < player_x:
		visuals.scale.x = -1
	elif mouse_x > player_x:
		visuals.scale.x = 1
		
	state_label.text = State.keys()[current_state]

	match current_state:
		State.IDLE, State.MOVE, State.MOVE_TO_IDLE, State.DASH_TO_IDLE:
			if not is_input_locked: # 입력이 잠겨있지 않을 때만 스태미나를 회복합니다.
				regenerate_stamina(delta)

	match current_state:
		State.IDLE:
			state_logic_idle(delta)
		State.MOVE:
			state_logic_move(delta)
		State.MOVE_TO_IDLE:
			state_logic_move_to_idle(delta)
		State.DASH:
			state_logic_dash(delta)
		State.DASH_TO_IDLE:
			state_logic_dash_to_idle(delta)
		State.SKILL_CASTING:
			state_logic_skill_casting(delta)
	
	stamina_bar.value = current_stamina
	
	move_and_slide()


func regenerate_stamina(delta: float):
	current_stamina = clamp(current_stamina + stamina_regen_rate * delta, 0, max_stamina)

# -------------------------------------------------------------------
# 상태별 로직
# -------------------------------------------------------------------

func state_logic_idle(_delta: float):
	velocity = Vector2.ZERO
	
	# 키 입력을 처리합니다.
	handle_inputs()
	if is_input_locked:
		return # 입력이 잠겨있으면 아래 이동 로직을 실행하지 않습니다.
	
	if Input.get_vector("move_left", "move_right", "move_up", "move_down"):
		change_state(State.MOVE)

func state_logic_move(delta: float):
	# 키 입력을 처리합니다.
	handle_inputs()
	if is_input_locked:
		# UI가 켜지면 그 자리에 멈추도록 감속
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		return

	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = velocity.move_toward(direction.normalized() * max_speed, acceleration * delta)
	else:
		change_state(State.MOVE_TO_IDLE)

func state_logic_move_to_idle(delta: float):
	# 키 입력을 처리합니다.
	handle_inputs()
	if is_input_locked:
		# UI가 켜지면 그 자리에 멈추도록 감속
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		return
		
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	if velocity == Vector2.ZERO:
		change_state(State.IDLE)
	elif Input.get_vector("move_left", "move_right", "move_up", "move_down"):
		velocity = Vector2.ZERO
		change_state(State.MOVE)

func state_logic_dash(_delta: float):
	velocity = dash_direction * dash_speed

func state_logic_dash_to_idle(delta: float):
	# 키 입력을 처리합니다.
	handle_inputs()
	if is_input_locked:
		velocity = velocity.move_toward(Vector2.ZERO, dash_friction * delta)
		return
		
	velocity = velocity.move_toward(Vector2.ZERO, dash_friction * delta)
	if velocity == Vector2.ZERO:
		change_state(State.IDLE)
	elif Input.get_vector("move_left", "move_right", "move_up", "move_down"):
		velocity = Vector2.ZERO
		change_state(State.MOVE)

func state_logic_skill_casting(delta: float):
	if current_casting_skill != null:
		current_casting_skill.process_skill_physics(self, delta)
		
		if current_casting_skill.ends_on_condition:
			if not current_casting_skill.is_active:
				_on_skill_cast_timeout()
				
	else:
		change_state(State.IDLE)


# -------------------------------------------------------------------
# 입력 처리
# -------------------------------------------------------------------
func handle_inputs():
	# 최우선으로 인벤토리 UI 토글 입력을 확인합니다. 이 기능은 입력 잠금 상태에서도 동작해야 합니다.
	if Input.is_action_just_pressed("ui_inventory"):
		skill_ui.visible = not skill_ui.visible
		
		# UI의 표시 여부에 따라 플레이어 입력 잠금 상태를 설정합니다.
		is_input_locked = skill_ui.visible
		
		if skill_ui.visible:
			skill_ui.refresh_ui(self)
		
		return # UI 키를 누른 프레임에는 다른 입력을 처리하지 않습니다.

	# 입력이 잠겨 있다면, 아래의 스킬 사용이나 대시 등의 입력을 무시합니다.
	if is_input_locked:
		return

	# --- (입력이 잠기지 않았을 때만 아래 코드가 실행됨) ---
		
	if Input.is_action_just_pressed("skill_1"):
		var target = find_mouse_target()
		try_cast_skill(skill_1_slot, target)
		
	elif Input.is_action_just_pressed("skill_2"):
		try_cast_skill(skill_2_slot, null)

	elif Input.is_action_just_pressed("skill_3"):
		try_cast_skill(skill_3_slot)

	elif Input.is_action_just_pressed("dash") and can_dash:
		if current_stamina >= dash_cost:
			change_state(State.DASH)
		else:
			pass

# -------------------------------------------------------------------
# 스킬 시도 및 장착
# -------------------------------------------------------------------
func find_mouse_target() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	if not results.is_empty():
		for result in results:
			var collider = result.collider
			if collider.is_in_group("enemies"):
				return collider

	return null

func try_cast_skill(slot_node: Node, target: Node2D = null):
	if slot_node.get_child_count() == 0:
		print("슬롯이 비어있음")
		return

	var skill: BaseSkill = slot_node.get_child(0)
	if skill == null: return

	if skill.requires_target and target == null:
		print(skill.skill_name + "은(는) 적을 클릭해야 합니다.")
		return

	if skill.requires_target and skill.max_cast_range > 0:
		var distance = global_position.distance_to(target.global_position)
		if distance > skill.max_cast_range:
			print(skill.skill_name + "의 사거리가 닿지 않습니다!")
			return
		
		print(str(distance) + "거리")
		print(str(skill.max_cast_range) + "사거리")

	if skill.is_ready() and current_stamina >= skill.stamina_cost:
		current_casting_skill = skill
		current_cast_target = target
		change_state(State.SKILL_CASTING)
	else:
		print(skill.skill_name + " 스킬 준비 안 됨 (쿨타임 또는 스태미나 부족)")

func equip_skill(skill_scene_path: String, slot_number: int):
	var slot_node: Node = null
	
	match slot_number:
		1:
			slot_node = skill_1_slot
		2:
			slot_node = skill_2_slot
		3:
			slot_node = skill_3_slot
		_:
			print("잘못된 슬롯 번호입니다.")
			return

	if slot_node.get_child_count() > 0:
		for child in slot_node.get_children():
			child.queue_free()

	var skill_scene = load(skill_scene_path)
	if skill_scene == null:
		print("스킬 씬 경로 오류: " + skill_scene_path)
		return
		
	var new_skill_instance = skill_scene.instantiate()
	
	slot_node.add_child(new_skill_instance)
	
	if new_skill_instance is BaseSkill:
		print(new_skill_instance.skill_name + "을(를) " + str(slot_number) + "번 슬롯에 장착!")
	else:
		print("장착된 씬이 BaseSkill.gd를 상속받지 않았습니다.")

# -------------------------------------------------------------------
# 상태 변경 (진입 로직)
# -------------------------------------------------------------------
func change_state(new_state: State):
	if current_state == new_state:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			pass
			
		State.MOVE:
			pass
		
		State.MOVE_TO_IDLE:
			pass
			
		State.DASH:
			current_stamina -= dash_cost
			
			var mouse_position = get_global_mouse_position()
			dash_direction = (mouse_position - global_position).normalized()
			
			if dash_direction == Vector2.ZERO:
				change_state(State.IDLE)
				return

			can_dash = false
			duration_timer.wait_time = dash_duration
			duration_timer.start()
	
		State.DASH_TO_IDLE:
			pass

		State.SKILL_CASTING:
			if current_casting_skill == null: return
			current_casting_skill.execute(self, current_cast_target)
			current_stamina -= current_casting_skill.stamina_cost
			current_casting_skill.start_cooldown()
			
			if not current_casting_skill.ends_on_condition:
				skill_cast_timer.wait_time = current_casting_skill.cast_duration
				skill_cast_timer.start()

# -------------------------------------------------------------------
# 타이머 시그널
# -------------------------------------------------------------------
func _on_dash_duration_timeout():
	change_state(State.DASH_TO_IDLE)
	cooldown_timer.wait_time = dash_cooldown
	cooldown_timer.start()

func _on_dash_cooldown_timeout():
	can_dash = true

func _on_skill_cast_timeout():
	change_state(State.IDLE)
	current_casting_skill = null
	current_cast_target = null

# -------------------------------------------------------------------
# 피격 및 사망 (잔기 방식)
# -------------------------------------------------------------------
func update_lives_ui():
	for child in lives_container.get_children():
		child.queue_free()
		
	if life_icon:
		for i in range(current_lives):
			var icon = TextureRect.new()
			icon.texture = life_icon
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(32, 32)
			lives_container.add_child(icon)

func lose_life():
	if is_invincible or current_state == State.DASH or current_lives <= 0:
		return

	current_lives -= 1
	print("생명 1 잃음! 남은 생명: ", current_lives)
	update_lives_ui()
	
	if current_lives <= 0:
		die()
	else:
		is_invincible = true
		i_frames_timer.wait_time = i_frames_duration
		i_frames_timer.start()

func die():
	print("플레이어가 사망했습니다.")
	is_invincible = false
	visuals.visible = true
	get_tree().reload_current_scene()
	
func _on_i_frames_timeout():
	is_invincible = false
	visuals.visible = true
