# ui/SkillCard.gd
extends PanelContainer

# SkillUI.gd가 이 카드에 채워줄 스킬 정보입니다.
var skill_path: String
var skill_icon: Texture
var skill_name: String
var skill_description: String
var skill_type: int # 스킬 타입 (1, 2, 3)

# (호버 효과를 위한 스타일)
var hover_stylebox: StyleBoxFlat
var default_stylebox: StyleBoxFlat

func _ready():
	# 호버 스타일
	hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = Color(1, 1, 1, 0.15)
	hover_stylebox.corner_radius_top_left = 4
	hover_stylebox.corner_radius_top_right = 4
	hover_stylebox.corner_radius_bottom_left = 4
	hover_stylebox.corner_radius_bottom_right = 4

	# 기본 스타일
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	
	setup_card_ui()


func setup_card_ui():
	tooltip_text = skill_description
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	var icon = TextureRect.new()
	icon.texture = skill_icon
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(128, 128)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var name_label = Label.new()
	name_label.text = skill_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(160, 0)
	
	vbox.add_child(icon)
	vbox.add_child(name_label)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)


# 드래그 시작 시, 장착 슬롯에서 타입을 확인할 수 있도록 데이터를 구성합니다.
func _get_drag_data(at_position):
	var drag_data = {
		"type": "skill",
		"path": skill_path,
		"skill_type_int": skill_type
	}
	
	var preview = TextureRect.new()
	preview.texture = skill_icon
	preview.custom_minimum_size = Vector2(128, 128)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	set_drag_preview(preview)
	return drag_data


# --- 호버 효과 ---
func _on_mouse_entered():
	if hover_stylebox:
		add_theme_stylebox_override("panel", hover_stylebox)

func _on_mouse_exited():
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)