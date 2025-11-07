# skills/parry/Skill_Parry.gd
extends BaseSkill

# 패링 판정에 사용될 'ParryBox' (Area2D) 노드입니다.
@onready var parry_box = $ParryBox

func _ready():
    super._ready()
    # 스킬이 처음 로드될 때, 패링 판정 영역을 비활성화 상태로 시작합니다.
    if parry_box:
        # Area2D의 감지 기능(monitoring) 자체를 꺼서 불필요한 충돌 검사를 방지합니다.
        parry_box.monitoring = false

# BaseSkill의 execute 함수를 오버라이드하여 패링 스킬의 동작을 정의합니다.
func execute(owner: CharacterBody2D, target: Node2D = null):
    print(owner.name + "가 " + skill_name + " 시전!")
    
    # 패링 판정을 활성화합니다.
    if parry_box:
        parry_box.monitoring = true
    
    # 패링 지속 시간(cast_duration)이 지나면 판정이 자동으로 비활성화되도록 타이머를 설정합니다.
    get_tree().create_timer(cast_duration).timeout.connect(_on_parry_finished)


# 패링 지속 시간이 종료되었을 때 호출됩니다.
func _on_parry_finished():
    # 패링 판정을 비활성화합니다.
    if parry_box:
        parry_box.monitoring = false

# 스킬 시전 중 매 물리 프레임마다 호출됩니다.
func process_skill_physics(owner: CharacterBody2D, delta: float):
    # 패링 중에는 플레이어가 움직이지 않도록 속도를 0으로 고정합니다.
    owner.velocity = Vector2.ZERO

# ParryBox 영역에 다른 Area2D(예: 총알)가 들어왔을 때 호출됩니다.
func _on_parry_box_area_entered(area):
    # 감지된 area가 "enemy_attacks" 그룹에 속하는지 확인합니다.
    if area.is_in_group("enemy_attacks"):
        print("★★★ 패링 성공! ★★★")
        
        # 패링에 성공한 투사체(area)를 즉시 제거합니다.
        area.queue_free()
        
        # TODO: 패링 성공 시 보상 로직을 추가합니다. (예: 스태미나 회복)
        
        # 성공 시에는 지속 시간이 남아있더라도 즉시 패링 판정을 종료합니다.
        _on_parry_finished()