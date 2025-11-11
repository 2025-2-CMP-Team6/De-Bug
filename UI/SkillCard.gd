# SkillCard.gd
extends PanelContainer
# (class_name을 추가하는 것이 좋습니다)
class_name SkillCard

#region 변수
var skill_path: String
var skill_icon: Texture
var skill_name: String
var skill_description: String
var skill_type: int

var hover_stylebox: StyleBoxFlat
var default_stylebox: StyleBoxFlat
#endregion

#region UI 설정
func _ready():
	hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = Color(1, 1, 1, 0.15)
	hover_stylebox.set_corner_radius_all(4)

	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	
	# ★ (수정) _ready()에서 setup_card_ui() 호출을 '삭제'합니다.
	# setup_card_ui()는 이제 SkillUI.gd의 refresh_ui()에서만 호출됩니다.
	# setup_card_ui() 
	
	# (수정) _ready가 아닌 setup_card_ui에서 연결하므로 이 코드는 setup_card_ui로 이동
	# mouse_entered.connect(_on_mouse_entered)
	# mouse_exited.connect(_on_mouse_exited)
	
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)


func setup_card_ui():
	tooltip_text = skill_description
	
	# (수정) VBox가 중복 생성되는 것을 방지
	var vbox = $VBoxContainer as VBoxContainer
	if not is_instance_valid(vbox):
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(vbox)

	var icon = vbox.get_node_or_null("Icon") as TextureRect
	if not is_instance_valid(icon):
		icon = TextureRect.new()
		icon.name = "Icon"
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(128, 128)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vbox.add_child(icon)
	
	icon.texture = skill_icon # 아이콘 텍스처 설정
	
	var name_label = vbox.get_node_or_null("NameLabel") as Label
	if not is_instance_valid(name_label):
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.custom_minimum_size = Vector2(160, 0)
		vbox.add_child(name_label)

	name_label.text = skill_name # 이름 설정
	
	# ★ (수정) _ready()에서 여기로 이동
	#    (시그널이 아직 연결되지 않았을 때만 연결)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)

#endregion

#region 드래그 앤 드롭
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

#endregion

#region 호버 효과
func _on_mouse_entered():
	if hover_stylebox:
		add_theme_stylebox_override("panel", hover_stylebox)

func _on_mouse_exited():
	if default_stylebox:
		add_theme_stylebox_override("panel", default_stylebox)
#endregion