# actors/enemies/enemy.gd
extends CharacterBody2D

# 1. 총알 씬(프리팹)을 미리 불러옵니다.
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")

# 2. 노드 캐시
@onready var fire_timer = $FireTimer
@onready var muzzle = $Muzzle

func _ready():
	# 3. FireTimer의 'timeout' 시그널을 'shoot' 함수에 연결
	fire_timer.timeout.connect(shoot)

# 4. 'timeout' 시그널이 울릴 때마다(2초마다) 이 함수가 실행됨
func shoot():
	# 5. 랜덤한 방향(Vector2) 생성
	var random_angle = randf_range(0, TAU) # TAU = 2 * PI (360도)
	var direction = Vector2.RIGHT.rotated(random_angle)
	
	# 6. 총알 씬(프리팹)을 '인스턴스화' (복제)
	var bullet = BULLET_SCENE.instantiate()
	
	# 7. 총알의 변수 설정
	bullet.direction = direction
	bullet.global_position = muzzle.global_position # 총구의 '월드' 위치에서 발사
	
	# 8. 총알을 맵(월드)에 추가
	# (적의 자식이 아니라, 맵의 자식으로 추가해야 적이 움직여도 총알이 안 따라다님)
	get_parent().add_child(bullet)
