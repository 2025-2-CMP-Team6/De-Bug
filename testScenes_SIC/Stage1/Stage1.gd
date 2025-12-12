extends World

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/stage1.dialogue")

# 리스폰 관련 변수
var spawn_position: Vector2 = Vector2(310.99988, 5081.0005) # 플레이어 시작 위치
var current_respawn_position: Vector2 # 현재 리스폰 위치 (가장 최근 죽인 적의 위치)
var highest_checkpoint_number: int = 0 # 현재 체크포인트로 설정된 적의 번호 (가장 높은 번호만 유지)

# 튜토리얼 관련 변수
var is_first_skill_selection: bool = false # 튜토리얼 보스 처치 후 첫 스킬 선택인지 추적

func _ready():
	super() #오디오매니저 세팅을 위해 필요합니다. 인스펙터의 Stage Settings에 원하는 음악을 넣으면 됩니다.

	# 리스폰 위치 초기화
	current_respawn_position = spawn_position

	# 튜토리얼 적들의 체크포인트 연결
	_connect_enemy_checkpoints()

	# 튜토리얼 트리거 신호 연결 (씬에 존재하는 경우)
	_connect_tutorial_triggers()

	# 튜토리얼 보스 처치 시 스킬창 해제
	_connect_tutorial_boss()

	# 스킬 선택 후 dialogue 표시를 위한 신호 연결
	if is_instance_valid(skill_get_ui):
		skill_get_ui.closed.connect(_on_first_skill_selected)

	# 카메라 인트로 효과 실행 (world.gd의 공통 함수 사용)
	await camera_intro_effect()

	# 플레이어 찾기
	var stage_player = player if player != null else get_node_or_null("Player")

	# 인트로 대화 시작 전에 플레이어 입력 잠금
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("=== 인트로 시작: 플레이어 입력 잠금 ===")

	# 인트로 효과가 끝난 후 대화 시작
	var balloon = DialogueManager.show_dialogue_balloon_scene("res://testScenes_SIC/dialogue/stage1_balloon.tscn", dialogue_resource, "start")

	# balloon의 dialogue_finished 신호 연결
	balloon.dialogue_finished.connect(_on_dialogue_ended)

# 튜토리얼 적들의 체크포인트 연결
func _connect_enemy_checkpoints():
	# virus, virus2, virus3의 enemy_died 신호를 연결
	var enemies_to_track = ["Virus", "Virus2", "Virus3"]

	for enemy_name in enemies_to_track:
		var enemy = get_node_or_null(enemy_name)
		if enemy and enemy.has_signal("enemy_died"):
			# 적이 죽을 때 해당 적의 위치를 체크포인트로 설정
			enemy.enemy_died.connect(func(): _on_enemy_checkpoint_reached(enemy, enemy_name))
			print("체크포인트 연결됨: ", enemy_name)

func _on_enemy_checkpoint_reached(enemy: Node2D, enemy_name: String):
	# 적 이름에서 번호 추출 ("Virus" -> 1, "Virus2" -> 2, "Virus3" -> 3)
	var enemy_number = _extract_enemy_number(enemy_name)

	print("=== 적 처치: ", enemy_name, " (번호: ", enemy_number, ") ===")
	print("현재 최고 체크포인트 번호: ", highest_checkpoint_number)

	# 더 높은 번호의 적을 죽였을 때만 체크포인트 업데이트
	if enemy_number > highest_checkpoint_number:
		highest_checkpoint_number = enemy_number
		current_respawn_position = enemy.global_position
		print(">>> 체크포인트 갱신! 새 리스폰 위치: ", current_respawn_position)
	else:
		print(">>> 체크포인트 유지 (현재 체크포인트가 더 높은 번호)")

# 적 이름에서 번호를 추출하는 함수
func _extract_enemy_number(enemy_name: String) -> int:
	# "Virus" -> 1, "Virus2" -> 2, "Virus3" -> 3
	if enemy_name == "Virus":
		return 1
	elif enemy_name.begins_with("Virus"):
		# "Virus2", "Virus3" 등에서 숫자 부분만 추출
		var number_part = enemy_name.substr(5)  # "Virus" 다음 문자들
		if number_part.is_valid_int():
			return int(number_part)
	return 0  # 알 수 없는 경우 0 반환

# 튜토리얼 보스 처치 시 스킬창 해제
func _connect_tutorial_boss():
	var tutorial_boss = get_node_or_null("TutorialBoss")
	if tutorial_boss and tutorial_boss.has_signal("enemy_died"):
		tutorial_boss.enemy_died.connect(_on_tutorial_boss_defeated)
		print("튜토리얼 보스 신호 연결됨")

func _on_tutorial_boss_defeated():
	print("=== 튜토리얼 보스 처치! ===")

	# 첫 스킬 선택 플래그 설정
	is_first_skill_selection = true

	# 플레이어 찾기
	var stage_player = player if player != null else get_node_or_null("Player")

	# 플레이어 입력 잠금 (dialogue 표시 중)
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("플레이어 입력 잠금 (보스 처치 후 dialogue)")

	# 보스 처치 후 dialogue 시작
	var balloon = DialogueManager.show_dialogue_balloon_scene(
		"res://testScenes_SIC/dialogue/stage1_balloon.tscn",
		dialogue_resource,
		"tutorial_boss_defeated"
	)

	# dialogue가 끝나면 플레이어 입력 잠금 해제 (스킬 선택 창이 열림)
	balloon.dialogue_finished.connect(func():
		if stage_player and stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("플레이어 입력 잠금 해제 - 스킬 선택 가능")
	)

# 첫 스킬 선택 후 호출되는 함수
func _on_first_skill_selected():
	# 첫 스킬 선택이 아니면 무시
	if not is_first_skill_selection:
		return

	is_first_skill_selection = false
	print("=== 첫 스킬 선택 완료! ===")

	# 플레이어 찾기
	var stage_player = player if player != null else get_node_or_null("Player")

	# 플레이어 입력 잠금 (dialogue 표시 중)
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("플레이어 입력 잠금 (스킬 설명 dialogue)")

	# 스킬 사용법 설명 dialogue 시작
	var balloon = DialogueManager.show_dialogue_balloon_scene(
		"res://testScenes_SIC/dialogue/stage1_balloon.tscn",
		dialogue_resource,
		"after_skill_selection"
	)

	# dialogue가 끝나면 스킬창 해제 및 플레이어 입력 잠금 해제
	balloon.dialogue_finished.connect(func():
		unlock_skill_ui()
		if stage_player and stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("플레이어 입력 잠금 해제 - 게임 계속")
	)

# 튜토리얼 트리거들의 신호 자동 연결
func _connect_tutorial_triggers():
	# TutorialTrigger_Dash 연결
	var dash_trigger = get_node_or_null("DashTutorial")
	if dash_trigger:
		dash_trigger.body_entered.connect(func(body): _on_tutorial_trigger_entered(body, "dash", "tutorial_dash"))
		print("대시 튜토리얼 트리거 연결됨")

	# 추가 튜토리얼 트리거가 있다면 여기에 추가
	var skill_trigger = get_node_or_null("SkillTutorial")
	if skill_trigger:
		skill_trigger.body_entered.connect(func(body): _on_tutorial_trigger_entered(body, "skill", "tutorial_skill"))
		
	var middleBoss_trigger = get_node_or_null("MiddleBossTutorial")
	if middleBoss_trigger:
		middleBoss_trigger.body_entered.connect(func(body): _on_tutorial_trigger_entered(body, "middleBoss", "tutorial_middleBoss"))

func _on_fall_prevention_body_entered(body: Node2D):
	if body.is_in_group("player"):
		respawn_player(body)

func respawn_player(player: Node2D):
	if player:
		# 플레이어를 현재 체크포인트 위치로 이동
		player.global_position = current_respawn_position
		# 속도 초기화
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		print("플레이어가 리스폰되었습니다! 위치: ", current_respawn_position)

# 첫 번째 dialogue 종료 여부 추적
var first_dialogue_done: bool = false

# 튜토리얼 트리거 추적 (한 번만 실행되도록)
var tutorial_triggers_activated: Dictionary = {}

# dialogue가 끝났을 때 호출되는 함수
func _on_dialogue_ended():
	if not first_dialogue_done:
		# 첫 번째 dialogue가 끝났을 때만 카메라 줌 실행
		print("=== 첫 번째 dialogue 종료, 포탈 줌 시작 ===")
		first_dialogue_done = true

		# 포탈로 카메라 줌 효과 실행 (입력은 계속 잠금 상태 유지)
		await camera_zoom_to_portal(2.0, 1.5, Vector2(1.5, 1.5), Vector2(-400, 200))

		# 카메라 줌이 끝난 후 두 번째 dialogue 시작
		print("=== 포탈 줌 완료, 두 번째 dialogue 시작 ===")
		var balloon = DialogueManager.show_dialogue_balloon_scene("res://testScenes_SIC/dialogue/stage1_balloon.tscn", dialogue_resource, "after_portal")
		balloon.dialogue_finished.connect(_on_dialogue_ended)
	else:
		# 두 번째 dialogue가 끝났을 때 - 이제 플레이어 입력 잠금 해제
		print("=== 모든 인트로 dialogue 완료, 플레이어 입력 잠금 해제 ===")

		var stage_player = player if player != null else get_node_or_null("Player")
		if stage_player and stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("플레이어가 이제 움직일 수 있습니다!")

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

# 튜토리얼 트리거 처리 (Area2D의 body_entered 신호에 연결)
func _on_tutorial_trigger_entered(body: Node2D, trigger_name: String, dialogue_title: String):
	# 플레이어가 아니면 무시
	if not body.is_in_group("player"):
		return

	# 이미 활성화된 트리거면 무시 (한 번만 실행)
	if tutorial_triggers_activated.get(trigger_name, false):
		return

	print("=== 튜토리얼 트리거 활성화: ", trigger_name, " ===")
	tutorial_triggers_activated[trigger_name] = true

	# 플레이어 찾기
	var stage_player = player if player != null else body

	# 플레이어 입력 잠금 (움직임 금지)
	if stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("플레이어 입력 잠금")

	# skill 튜토리얼인 경우 모든 적 AI 비활성화
	var paused_enemies = []
	if trigger_name == "skill":
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy and is_instance_valid(enemy):
				enemy.set_process(false)
				enemy.set_physics_process(false)
				paused_enemies.append(enemy)
		print("적 AI 비활성화: ", paused_enemies.size(), "마리")

	# 튜토리얼 대화 시작
	var balloon = DialogueManager.show_dialogue_balloon_scene(
		"res://testScenes_SIC/dialogue/stage1_balloon.tscn",
		dialogue_resource,
		dialogue_title
	)

	# 대화가 끝나면 플레이어 입력 잠금 해제 및 적 AI 복원
	balloon.dialogue_finished.connect(func():
		if stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("플레이어 입력 잠금 해제")

		# skill 튜토리얼이었다면 적 AI 다시 활성화
		if trigger_name == "skill":
			for enemy in paused_enemies:
				if enemy and is_instance_valid(enemy):
					enemy.set_process(true)
					enemy.set_physics_process(true)
			print("적 AI 활성화: ", paused_enemies.size(), "마리")
	)

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# World의 포탈 체크 먼저 실행 (모든 적 처치 확인)
	if not portal_enabled:
		print(">>> 아직 포탈을 사용할 수 없습니다! 모든 적을 처치하세요. <<<")
		return

	print("플레이어가 포탈에 진입했습니다!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage2/Stage2.tscn")
