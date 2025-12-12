# BoobyTrap.gd
extends Area2D

@export var damage_cooldown: float = 1.0  # 데미지를 입히는 쿨타임 (초)
@export var damage_amount: int = 1  # 입히는 생명 개수

var can_damage: bool = true
var damage_timer: Timer

func _ready():
	# 플레이어의 collision_layer 확인
	await get_tree().process_frame  # 플레이어가 로드될 때까지 대기
	var player = get_tree().get_first_node_in_group("player")

	# body_entered 시그널 연결
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 데미지 쿨타임 타이머 생성
	damage_timer = Timer.new()
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_cooldown_timeout)
	add_child(damage_timer)

func _on_body_entered(body: Node2D):
	# 플레이어인지 확인
	if body.is_in_group("player"):
		print("  -> 플레이어 감지! 데미지 적용")
		apply_trap_damage(body)
	else:
		print("  -> 플레이어 아님, 데미지 무시")

func _on_body_exited(body: Node2D):
	# 플레이어가 벗어나면 쿨타임 리셋
	if body.is_in_group("player"):
		can_damage = true
		if damage_timer.is_stopped() == false:
			damage_timer.stop()

func apply_trap_damage(player: Node2D):
	# 쿨타임 중이면 데미지 무시
	if not can_damage:
		return

	# 플레이어에게 데미지
	if player.has_method("lose_life"):
		for i in range(damage_amount):
			player.lose_life()
		print("부비트랩 발동! 플레이어가 데미지를 입었습니다.")

		# 쿨타임 시작
		can_damage = false
		damage_timer.wait_time = damage_cooldown
		damage_timer.start()

func _on_damage_cooldown_timeout():
	can_damage = true
