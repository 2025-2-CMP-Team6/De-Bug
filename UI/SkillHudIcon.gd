# SkillHudIcon.gd
extends Control

#region 노드 참조
@onready var icon_rect: TextureRect = $Icon
@onready var cooldown_bar: ProgressBar = $CooldownBar
@onready var cooldown_label: Label = $CooldownLabel
@onready var keybind_label: Label = $KeybindLabel
#endregion

#region 변수
var skill_slot_node: Node = null
var keybind_text: String = ""
#endregion

#region 초기화
func _ready():
	# 1. 아이콘/프로그레스바 레이아웃 설정
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# (추가) 아이콘이 할당된 사각형을 꽉 채우도록 설정
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cooldown_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 2. (수정) 키 바인드 라벨 (KeybindLabel)
	# 2-1. 앵커를 '우측 상단'으로 변경합니다.
	keybind_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	# 2-2. (추가) 폰트 크기를 키웁니다. (원하는 크기로 조절하세요)
	keybind_label.add_theme_font_size_override("font_size", 24)
	# 2-3. (추가) 위치를 살짝 '벗어나게' 조절 (우측 상단 기준)
	# (컨테이너 밖으로 x +5, y -10 만큼 이동)
	keybind_label.position = Vector2(5, -10)

	# 3. (수정) ProgressBar 스타일 (여백 제거)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0, 0, 0, 0.7)
	fill_style.set_content_margin_all(0) # (추가) 내부 여백 0
	cooldown_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color.TRANSPARENT
	bg_style.set_content_margin_all(0) # (추가) 내부 여백 0
	cooldown_bar.add_theme_stylebox_override("background", bg_style)
	
	# 처음엔 비어있는 상태로 시작
	_clear_display()

# public 함수: 이 UI를 초기화하고 키 바인드를 설정합니다.
func setup_hud(slot_node: Node, key_text: String):
	self.skill_slot_node = slot_node
	self.keybind_text = key_text
	keybind_label.text = keybind_text
#endregion

#region 매 프레임 업데이트
func _process(_delta):
	# (이하 코드는 이전과 동일합니다)
	if not is_instance_valid(skill_slot_node) or skill_slot_node.get_child_count() == 0:
		_clear_display()
		return

	var skill = skill_slot_node.get_child(0) as BaseSkill
	if not is_instance_valid(skill):
		_clear_display()
		return

	icon_rect.texture = skill.skill_icon
	
	var time_left = skill.get_cooldown_time_left()
	var total_cooldown = skill.cooldown
	
	if time_left > 0:
		cooldown_label.visible = true
		cooldown_bar.visible = true
		
		cooldown_label.text = "%.1f" % time_left
		
		if total_cooldown > 0:
			cooldown_bar.value = (total_cooldown - time_left) / total_cooldown
		else:
			cooldown_bar.value = 1.0
		
		icon_rect.modulate = Color(0.5, 0.5, 0.5)
	else:
		_set_ready_display(skill.skill_icon)

#endregion

#region UI 상태 변경
func _clear_display():
	icon_rect.texture = null
	icon_rect.modulate = Color(0.2, 0.2, 0.2)
	cooldown_label.visible = false
	cooldown_bar.visible = false
	cooldown_bar.value = 0.0

func _set_ready_display(skill_icon: Texture):
	icon_rect.texture = skill_icon
	icon_rect.modulate = Color.WHITE
	cooldown_label.visible = false
	cooldown_bar.visible = false
	cooldown_bar.value = 0.0
#endregion
