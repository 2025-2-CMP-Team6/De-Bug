extends Camera2D

func _ready():
	# 씬 트리가 준비되면 0.1초 정도 기다렸다가 설정을 시작합니다.
	# (다른 노드들이 모두 로딩되고 자리를 잡을 시간을 주기 위함입니다)
	await get_tree().process_frame 
	
	find_and_set_limits()

func find_and_set_limits():
	var background_node = get_tree().get_first_node_in_group("CameraMapLimit")
	
	if background_node == null:
		print("경고: 'MapLimit' 그룹을 가진 배경 노드를 찾을 수 없습니다.")
		return
		
	if not background_node is Sprite2D:
		print("경고: 찾은 노드가 Sprite2D가 아닙니다.")
		return

	# 배경 노드를 찾았다면 한계 설정 함수를 호출합니다.
	set_limits_from_sprite(background_node)

func set_limits_from_sprite(sprite: Sprite2D):
	# 스프라이트의 글로벌 사각형 범위 계산
	var rect = sprite.get_rect()
	var global_rect = sprite.get_global_transform() * rect
	
	# 카메라 리밋 설정
	limit_left = int(global_rect.position.x)
	limit_top = int(global_rect.position.y)
	limit_right = int(global_rect.end.x)
	limit_bottom = int(global_rect.end.y)
	
	print("카메라 범위 설정 완료: ", global_rect)
