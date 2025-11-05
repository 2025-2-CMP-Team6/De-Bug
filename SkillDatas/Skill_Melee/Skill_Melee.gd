# Skill_Melee.gd
extends BaseSkill

# 'CollisionShape2D' 대신 'Hitbox (Area2D)' 노드 자체를 캐시합니다.
@onready var hitbox = $Hitbox

func _ready():
	# 게임 시작 시 히트박스 노드를 완전히 숨기고 비활성화합니다.
	if hitbox:
		hitbox.visible = false

# 'BaseSkill.gd'에 있는 'execute' 함수의 내용을 덮어씁니다.
func execute(owner: CharacterBody2D, target: Node2D = null):
	# super.execute(owner, target) # (필요하면 부모 호출)
	# 1. 히트박스 노드를 보이게 하고 + 물리 활성화
	if hitbox:
		hitbox.visible = true
	
	# 2. 'cast_duration' 시간 후에 히트박스를 다시 끄도록 타이머 설정
	get_tree().create_timer(cast_duration).timeout.connect(_on_attack_finished)


# 공격 지속시간(cast_duration)이 끝났을 때 호출될 내부 함수
func _on_attack_finished():
	# 3. 히트박스 노드를 다시 숨기고 + 물리 비활성화
	if hitbox:
		hitbox.visible = false
		
func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity = Vector2.ZERO
