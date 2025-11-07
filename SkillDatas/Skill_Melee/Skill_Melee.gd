# Skill_Melee.gd
extends BaseSkill

@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/CollisionShape2D

func _ready():
	super._ready()
	if hitbox_shape:
		hitbox_shape.disabled = true
		
	# 히트박스가 다른 Area나 Body와 충돌했는지 감지하기 위해 시그널을 연결합니다.
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func execute(owner: CharacterBody2D, target: Node2D = null):
	# super.execute(owner, target) # 기본 execute 로직이 필요하다면 주석 해제
	if hitbox_shape:
		hitbox_shape.disabled = false
	
	get_tree().create_timer(cast_duration).timeout.connect(_on_attack_finished)

# 공격 지속 시간이 끝나면 히트박스를 비활성화합니다.
func _on_attack_finished():
	if hitbox_shape:
		hitbox_shape.disabled = true
		
# 근접 공격 중에는 플레이어가 움직이지 않도록 고정합니다.
func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity = Vector2.ZERO

# 히트박스가 Area2D(적의 Hurtbox 등)와 충돌했을 때 호출됩니다.
func _on_hitbox_area_entered(area):
	# 충돌한 area가 'enemies' 그룹에 속해 있다면 피격 효과를 재생합니다.
	# 이 방식은 적의 피격 판정이 Area2D일 때 작동합니다.
	if area.is_in_group("enemies"):
		EffectManager.play_screen_shake(8.0, 0.1)
		EffectManager.play_screen_flash(Color.WHITE, 0.05)

# 히트박스가 PhysicsBody2D(적의 CharacterBody2D 등)와 충돌했을 때 호출됩니다.
func _on_hitbox_body_entered(body):
	# 충돌한 body가 'enemies' 그룹에 속해 있다면 피격 효과를 재생합니다.
	if body.is_in_group("enemies"):
		EffectManager.play_screen_shake(8.0, 0.1)
		EffectManager.play_screen_flash(Color.WHITE, 0.05)