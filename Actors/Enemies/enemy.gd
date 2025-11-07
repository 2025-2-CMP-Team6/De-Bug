# actors/enemies/enemy.gd
extends CharacterBody2D

# 총알 발사 관련 노드 및 씬입니다.
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
@onready var fire_timer = $FireTimer
@onready var muzzle = $Muzzle

# 체력 관련 변수입니다.
@export var max_health: float = 100.0
var current_health: float

# 자주 사용하는 노드를 캐시합니다.
@onready var sprite = $Sprite2D
@onready var hurtbox = $Hurtbox
@onready var i_frames_timer = $IFramesTimer

# 상태 관련 변수입니다.
var is_invincible: bool = false

func _ready():
	# Godot 에디터에서 수동으로 연결된 시그널이 중복 연결되는 것을 방지하기 위해
	# 초기화 시점에 기존 연결을 모두 해제합니다. 노드가 null일 경우를 대비해 확인합니다.
	if fire_timer != null:
		for conn in fire_timer.timeout.get_connections():
			fire_timer.timeout.disconnect(conn.callable)
	
	if hurtbox != null:
		for conn in hurtbox.area_entered.get_connections():
			hurtbox.area_entered.disconnect(conn.callable)
	
	if i_frames_timer != null:
		for conn in i_frames_timer.timeout.get_connections():
			i_frames_timer.timeout.disconnect(conn.callable)
		
	# 스크립트 내에서 시그널을 다시 연결하여 동작을 보장합니다.
	if fire_timer != null:
		fire_timer.timeout.connect(shoot)
	
	if hurtbox != null:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	if i_frames_timer != null:
		i_frames_timer.timeout.connect(_on_i_frames_timeout)
	
	# 체력을 최대로 설정합니다.
	current_health = max_health
	
	# 다른 개체에 영향을 주지 않도록 쉐이더 머티리얼을 복제하여 사용합니다.
	if sprite and sprite.material:
		sprite.material = sprite.material.duplicate()
	
	# 피격 효과 쉐이더를 초기 상태(꺼짐)로 설정합니다.
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)

func _physics_process(_delta):
	# 무적 상태일 때 쉐이더를 이용해 점멸 효과를 표시합니다.
	if is_invincible:
		var is_flash_on = (int(Time.get_ticks_msec() / 100) % 2) == 0
		if is_flash_on:
			if sprite:
				EffectManager.set_hit_flash_amount(sprite, 1.0)
		else:
			if sprite:
				EffectManager.set_hit_flash_amount(sprite, 0.0)
	else:
		# 무적이 아닐 때는 점멸 효과가 없도록 쉐이더를 확실히 꺼줍니다.
		if sprite:
			EffectManager.set_hit_flash_amount(sprite, 0.0)

# 총알을 발사합니다.
func shoot():
	var random_angle = randf_range(0, TAU)
	var direction = Vector2.RIGHT.rotated(random_angle)
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = direction
	bullet.global_position = muzzle.global_position
	get_parent().add_child(bullet)


# 데미지를 받아 체력을 깎고, 무적 상태로 전환하거나 사망 처리합니다.
func take_damage(amount: float):
	if is_invincible or current_health <= 0:
		return

	current_health -= amount
	print(self.name + " 피격! 남은 체력: ", current_health)
	
	# 짧은 시간 동안 무적 상태가 됩니다.
	is_invincible = true
	if i_frames_timer != null:
		i_frames_timer.start()
	
	if current_health <= 0:
		die()

# Hurtbox 영역에 다른 Area가 들어왔을 때 호출됩니다.
func _on_hurtbox_area_entered(area):
	if area.is_in_group("player_attack"):
		var skill_node = area.get_parent()
		if skill_node != null and "damage" in skill_node:
			take_damage(skill_node.damage)
		else:
			take_damage(10.0) # 기본 데미지

# 적이 사망했을 때 처리 로직입니다.
func die():
	print(self.name + " 사망.")
	if fire_timer != null:
		fire_timer.stop()
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
	queue_free()

# 무적 시간이 종료되었을 때 호출됩니다.
func _on_i_frames_timeout():
	is_invincible = false
	if sprite:
		EffectManager.set_hit_flash_amount(sprite, 0.0)
