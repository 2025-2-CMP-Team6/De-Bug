# skills/parry/Skill_Parry.gd
extends BaseSkill

# 'ParryBox' (Area2D) 노드를 캐시할 변수
@onready var parry_box = $ParryBox

func _ready():
    # 스킬 씬이 로드될 때, 패링 판정을 비활성화 상태로 시작
    if parry_box:
        # Area2D는 monitoring(감지 기능)을 끄는 것이 가장 확실함
        parry_box.monitoring = false

# 'BaseSkill.gd'에 있는 'execute' 함수의 내용을 덮어씀
func execute(owner: CharacterBody2D, target: Node2D = null):
    print(owner.name + "가 " + skill_name + " 시전!")
    
    # 1. 패링 판정(monitoring)을 켭니다.
    if parry_box:
        parry_box.monitoring = true
    
    # 2. 'cast_duration' (패링 지속 시간) 후에 판정을 다시 끄도록 타이머 설정
    get_tree().create_timer(cast_duration).timeout.connect(_on_parry_finished)


# 패링 지속시간(cast_duration)이 끝났을 때 호출될 내부 함수
func _on_parry_finished():
    # 3. 패링 판정(monitoring)을 끕니다.
    if parry_box:
        parry_box.monitoring = false

# ★ "스킬 시전 중 물리 처리" (오버라이드)
func process_skill_physics(owner: CharacterBody2D, delta: float):
    # 패링 중에는 제자리에 멈춥니다.
    owner.velocity = Vector2.ZERO

# ★ (새로 추가) ParryBox가 무언가(총알)를 감지했을 때 호출될 함수
func _on_parry_box_area_entered(area):
    # 1. 감지한 'area'가 "enemy_attacks" 그룹에 속하는지 확인
    if area.is_in_group("enemy_attacks"):
        print("★★★ 패링 성공! ★★★")
        
        # 2. 총알(area)을 즉시 삭제
        area.queue_free()
        
        # 3. (나중에 여기에 보상 로직 추가)
        # 예: owner.current_stamina = owner.max_stamina (스태미나 전체 회복)
        
        # 4. 패링에 성공했으니 판정을 즉시 끈다.
        _on_parry_finished()