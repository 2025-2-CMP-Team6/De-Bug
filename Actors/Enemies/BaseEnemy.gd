# BaseEnemy.gd
class_name BaseEnemy extends CharacterBody2D

#region 속성
@export var max_health: float = 100.0
var current_health: float
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var effsize: float = 1.0
@export var is_boss: bool = false
@export var boss_ui_scene: PackedScene
@export var projectile_texture: Texture2D = null
var boss_ui_instance = null
const DEFAULT_BOSS_UI_PATH = "res://Actors/Enemies/Boss/boss_hp_bar.tscn"

# 사망 시그널
signal enemy_died
#endregion

#region 노드 참조
@onready var sprite = $Sprite2D
@onready var hurtbox = $Hurtbox
@onready var i_frames_timer = $IFramesTimer
#endregion

#region 상태 변수
var is_invincible: bool = false
#endregion

#region 초기화
func _ready():
	current_health = max_health
	
	# Hurtbox 연결
	if hurtbox != null:
		# 시그널 중복 연결 방지
		for conn in hurtbox.area_entered.get_connections():
			hurtbox.area_entered.disconnect(conn.callable)
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# 무적 시간 타이머 연결
	if i_frames_timer != null:
		for conn in i_frames_timer.timeout.get_connections():
			i_frames_timer.timeout.disconnect(conn.callable)
		i_frames_timer.timeout.connect(_on_i_frames_timeout)
	
	# 쉐이더 초기화
	if sprite:
		if sprite.material:
			sprite.material = sprite.material.duplicate()
		EffectManager.set_hit_flash_amount(sprite, 0.0)
	if is_boss:
		if boss_ui_scene == null:
			if ResourceLoader.exists(DEFAULT_BOSS_UI_PATH):
				boss_ui_scene = load(DEFAULT_BOSS_UI_PATH)
			else:
				print("오류: Boss UI 파일을 찾을 수 없습니다! 경로를 확인하세요: ", DEFAULT_BOSS_UI_PATH)
	if is_boss and boss_ui_scene:
		boss_ui_instance = boss_ui_scene.instantiate()
		add_child(boss_ui_instance)
		
		if boss_ui_instance.has_method("initialize"):
			boss_ui_instance.initialize(self.name, max_health, current_health)
#endregion

#region 물리 처리

func _physics_process(delta: float):
	# 중력
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 무적 상태 점멸 효과
	if is_invincible:
		var is_flash_on = (int(Time.get_ticks_msec() / 100) % 2) == 0
		if sprite:
			EffectManager.set_hit_flash_amount(sprite, 1.0 if is_flash_on else 0.0)
	else:
		if sprite:
			EffectManager.set_hit_flash_amount(sprite, 0.0)

	# 이동
	_process_movement(delta)
	move_and_slide()

# 자식 클래스로 오버라이드
func _process_movement(_delta: float):
	pass
#endregion

#region 피격 및 사망
func take_damage(amount: float):
	if is_invincible or current_health <= 0:
		return

	current_health -= amount
	print(self.name + " 피격! 남은 체력: ", current_health)
	EffectManager.play_hit_effect(global_position, effsize)
	is_invincible = true
	if i_frames_timer != null:
		i_frames_timer.start()
	if is_boss and is_instance_valid(boss_ui_instance):
		boss_ui_instance.update_health(current_health)

	if current_health <= 0:
		die()

func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_attack"):
		var skill_node = area.get_parent()
		if skill_node != null and "damage" in skill_node:
			take_damage(skill_node.damage)
		else:
			take_damage(10.0)

func die():
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
	if is_boss and is_instance_valid(boss_ui_instance):
		if boss_ui_instance.has_method("on_boss_died"):
			boss_ui_instance.on_boss_died()
	emit_signal("enemy_died")
	queue_free()

func _on_i_frames_timeout():
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
#endregion
