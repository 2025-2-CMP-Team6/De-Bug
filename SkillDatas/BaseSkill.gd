extends Node
class_name BaseSkill

#region Skill Properties
@export var skill_name: String = "기본 스킬"
@export var skill_description: String = "스킬 설명."
@export var skill_icon: Texture
@export var cast_duration: float = 0.3
@export var stamina_cost: float = 10.0
@export var cooldown: float = 1.0
@export var type: int = 1
@export var requires_target: bool = false
@export var ends_on_condition: bool = false
@export var damage: float = 10.0
# 스킬의 최대 시전 사거리 (0이면 무제한)
@export var max_cast_range: float = 0.0
#endregion

var cooldown_timer: Timer
var is_active: bool = false

func _ready():
	# _ready()는 노드가 씬 트리에 안전하게 추가된 후 호출되므로 타이머를 여기서 생성합니다.
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)

# 스킬 사용 가능 여부를 반환합니다.
func is_ready() -> bool:
	# _ready()가 실행되기 전(cooldown_timer가 null일 때) 호출될 경우를 대비합니다.
	if cooldown_timer == null:
		return false
		
	return cooldown_timer.is_stopped()

# 스킬을 시전합니다. (주로 Player가 호출)
func execute(owner: CharacterBody2D, target: Node2D = null):
	is_active = true
	print(owner.name + "가 " + skill_name + " 시전!")

# 스킬 쿨타임을 시작합니다.
func start_cooldown():
	# _ready()가 실행되기 전(cooldown_timer가 null일 때) 호출될 경우를 대비합니다.
	if cooldown_timer != null:
		cooldown_timer.wait_time = cooldown
		cooldown_timer.start()
		
# 스킬 시전 중 물리 프레임마다 호출될 로직입니다. (자식 스크립트에서 오버라이드)
func process_skill_physics(owner: CharacterBody2D, delta: float):
	pass

# 남은 쿨타임을 초 단위로 반환합니다.
func get_cooldown_time_left() -> float:
	if cooldown_timer != null:
		return cooldown_timer.time_left
	
	# 타이머가 아직 준비되지 않았다면 0을 반환합니다.
	return 0.0