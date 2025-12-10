extends World

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/stage1.dialogue")

# 리스폰 관련 변수
var spawn_position: Vector2 = Vector2(310.99988, 5081.0005) # 플레이어 시작 위치

func _ready():
	super() #오디오매니저 세팅을 위해 필요합니다. 인스펙터의 Stage Settings에 원하는 음악을 넣으면 됩니다.

	# 카메라 인트로 효과 실행 (world.gd의 공통 함수 사용)
	await camera_intro_effect()

	# 인트로 효과가 끝난 후 대화 시작
	var balloon = DialogueManager.show_dialogue_balloon_scene("res://testScenes_SIC/dialogue/stage1_balloon.tscn", dialogue_resource, "start")

	# balloon의 dialogue_finished 신호 연결
	balloon.dialogue_finished.connect(_on_dialogue_ended)

func _on_fall_prevention_body_entered(body: Node2D):
	if body.is_in_group("player"):
		respawn_player(body)

func respawn_player(player: Node2D):
	if player:
		# 플레이어를 시작 위치로 이동
		player.global_position = spawn_position
		# 속도 초기화
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		print("플레이어가 리스폰되었습니다!")

# 첫 번째 dialogue 종료 여부 추적
var first_dialogue_done: bool = false

# dialogue가 끝났을 때 호출되는 함수
func _on_dialogue_ended():
	if not first_dialogue_done:
		# 첫 번째 dialogue가 끝났을 때만 카메라 줌 실행
		print("=== 첫 번째 dialogue 종료, 포탈 줌 시작 ===")
		first_dialogue_done = true

		# 포탈로 카메라 줌 효과 실행
		await camera_zoom_to_portal(2.0, 1.5, Vector2(1.5, 1.5), Vector2(-400, 200))

		# 카메라 줌이 끝난 후 두 번째 dialogue 시작
		print("=== 포탈 줌 완료, 두 번째 dialogue 시작 ===")
		var balloon = DialogueManager.show_dialogue_balloon_scene("res://testScenes_SIC/dialogue/stage1_balloon.tscn", dialogue_resource, "after_portal")
		balloon.dialogue_finished.connect(_on_dialogue_ended)
	else:
		# 두 번째 dialogue가 끝났을 때
		print("=== 모든 dialogue 완료 ===")

# 포탈로 카메라를 줌인했다가 다시 플레이어로 돌아오는 효과
func camera_zoom_to_portal(
	portal_show_duration: float = 2.0,  # 포탈을 보여주는 시간
	zoom_duration: float = 1.5,         # 줌 이동 시간
	portal_zoom_level: Vector2 = Vector2(1.5, 1.5),  # 포탈 줌 레벨
	offset_adjustment: Vector2 = Vector2.ZERO  # 위치 미세 조정 (예: Vector2(50, -30))
):
	# 플레이어와 카메라 찾기
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player == null:
		print("경고: Player 노드를 찾을 수 없습니다.")
		return

	var camera = stage_player.get_node_or_null("Camera2D")
	if camera == null:
		print("경고: Player의 Camera2D를 찾을 수 없습니다.")
		return

	# 포탈 노드 찾기 (Stage1.tscn에 있는 portal 노드)
	var portal = get_node_or_null("portal")
	if portal == null:
		print("경고: Portal 노드를 찾을 수 없습니다.")
		print("사용 가능한 자식 노드들:")
		for child in get_children():
			print("  - ", child.name)
		return

	print("Portal 노드 찾음:", portal.name, " 위치:", portal.global_position)

	# 현재 카메라 설정 저장
	var original_offset = camera.offset
	var original_zoom = camera.zoom
	var original_smoothing = camera.position_smoothing_enabled

	# 카메라 스무딩 비활성화 (즉시 반응하게)
	camera.position_smoothing_enabled = false

	# 포탈의 중심 위치 계산
	# portal이 Area2D이므로 정확한 중심을 가져옴
	var portal_center = portal.global_position

	# 플레이어 기준으로 포탈까지의 offset 계산
	var portal_offset = portal_center - stage_player.global_position + offset_adjustment

	print("플레이어 위치:", stage_player.global_position)
	print("포탈 중심:", portal_center)
	print("계산된 offset:", portal_offset)
	print("조정값:", offset_adjustment)

	# 포탈 위치로 카메라 이동
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)  # 동시에 실행

	tween.tween_property(camera, "offset", portal_offset, zoom_duration)
	tween.tween_property(camera, "zoom", portal_zoom_level, zoom_duration)

	await tween.finished

	# 포탈을 잠시 보여주기
	await get_tree().create_timer(portal_show_duration).timeout

	# 다시 플레이어로 카메라 복귀
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.set_parallel(true)

	return_tween.tween_property(camera, "offset", original_offset, zoom_duration)
	return_tween.tween_property(camera, "zoom", original_zoom, zoom_duration)

	await return_tween.finished

	# 카메라 스무딩 원래대로 복원
	camera.position_smoothing_enabled = original_smoothing

func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		print("플레이어가 포탈에 진입했습니다!")
		# 여기에 포탈 이동 로직을 추가하세요
		SceneTransition.fade_to_scene("res://testScenes_SIC/Stage2/Stage2.tscn")
