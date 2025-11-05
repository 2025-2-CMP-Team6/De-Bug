# BaseSkill.gd
# Parents Scripts for Skills
extends Node
class_name BaseSkill

# --- Public Datas ---
@export var skill_name: String = "기본 스킬"
@export var skill_description: String = "스킬 설명."
@export var skill_icon: Texture
@export var cast_duration: float = 0.3
@export var stamina_cost: float = 10.0
@export var cooldown: float = 1.0
@export var type: int = 1
@export var requires_target: bool = false
@export var ends_on_condition: bool = false

## ★ (추가 1) 스킬의 데미지
@export var damage: float = 10.0
## ★ (추가 2) 스킬의 최대 시전 사거리 (0이면 무제한)
@export var max_cast_range: float = 0.0


var cooldown_timer: Timer
var is_active: bool = false


# initialize
func _init():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	
	call_deferred("add_child", cooldown_timer)


# Ready to Skill
func is_ready() -> bool:
	return cooldown_timer != null and cooldown_timer.is_stopped()

# Casting Skill (Owner - Player)
func execute(owner: CharacterBody2D, target: Node2D = null):
	is_active = true
	# (super.execute()가 print를 하도록 변경)
	print(owner.name + "가 " + skill_name + " 시전!")

# Cool Time
func start_cooldown():
	cooldown_timer.wait_time = cooldown
	cooldown_timer.start()
# Physics for Player
func process_skill_physics(owner: CharacterBody2D, delta: float):
# 기본적으로는 아무것도 안 함
	pass
