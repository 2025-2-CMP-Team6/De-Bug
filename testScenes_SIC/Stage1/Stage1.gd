extends World

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/stage1.dialogue")

func _ready():
	super() #오디오매니저 세팅을 위해 필요합니다. 인스펙터의 Stage Settings에 원하는 음악을 넣으면 됩니다.

	# 카메라 인트로 효과 실행
	await camera_intro_effect()

	# 인트로 효과가 끝난 후 대화 시작
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

# 카메라 인트로 효과: 맵 전체를 보여주고 플레이어로 줌인
func camera_intro_effect():
	# 플레이어 노드 찾기
	var player = get_node_or_null("Player")
	if player == null:
		print("경고: Player 노드를 찾을 수 없습니다.")
		return

	# 플레이어의 카메라 찾기
	var camera = player.get_node_or_null("Camera2D")
	if camera == null:
		print("경고: Player의 Camera2D를 찾을 수 없습니다.")
		return

	# Background 노드 찾기
	var background = get_node_or_null("Background")
	if background == null:
		print("경고: Background 노드를 찾을 수 없습니다.")
		return

	# 모든 Parallax2D 노드의 원래 scroll_scale 저장하고 임시로 1.0으로 설정
	var parallax_nodes = []
	var original_scroll_scales = []

	for child in background.get_children():
		if child is Parallax2D:
			parallax_nodes.append(child)
			original_scroll_scales.append(child.scroll_scale)
			child.scroll_scale = Vector2(1.0, 1.0)

	# 초기 줌 아웃 설정 (맵 전체를 보여주기 위해)
	var initial_zoom = Vector2(0.272, 0.3)  # 줌 아웃된 상태
	var target_zoom = Vector2(1.0, 1.0)     # 플레이어 중심 일반 줌

	camera.zoom = initial_zoom

	# 맵 전체를 잠시 보여주기 위해 대기
	await get_tree().create_timer(3).timeout

	# 플레이어 중심으로 줌 인 애니메이션과 동시에 scroll_scale도 부드럽게 복원
	var zoom_tween = create_tween()
	zoom_tween.set_ease(Tween.EASE_IN_OUT)
	zoom_tween.set_trans(Tween.TRANS_CUBIC)
	zoom_tween.tween_property(camera, "zoom", target_zoom, 2.0)

	# Parallax2D 노드들의 scroll_scale을 부드럽게 복원 (줌과 동시에)
	var parallax_tween = create_tween()
	parallax_tween.set_ease(Tween.EASE_IN_OUT)
	parallax_tween.set_trans(Tween.TRANS_CUBIC)
	parallax_tween.set_parallel(true)  # 모든 트윈을 동시에 실행

	for i in range(parallax_nodes.size()):
		parallax_tween.tween_property(parallax_nodes[i], "scroll_scale", original_scroll_scales[i], 2.0)

	# 애니메이션 완료까지 대기
	await zoom_tween.finished

func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		print("플레이어가 포탈에 진입했습니다!")
		# 여기에 포탈 이동 로직을 추가하세요
		get_tree().change_scene_to_file("res://testScenes_SIC/Stage2/Stage2.tscn")
