# ui/EquipSlot.gd
extends PanelContainer

# Godot 에디터의 인스펙터에서 이 슬롯의 번호(1, 2, 3)를 설정합니다.
@export var slot_index: int = 1

# 드롭이 성공하면 SkillUI에 스킬 경로와 슬롯 번호를 전달하는 시그널입니다.
signal skill_dropped_on_slot(skill_path: String, slot_index: int)

# 드래그 앤 드롭 시각 효과를 위한 스타일박스 변수입니다.
var default_stylebox: StyleBoxFlat
var can_drop_stylebox: StyleBoxFlat
var type_mismatch_stylebox: StyleBoxFlat # 스킬 타입이 맞지 않을 때 표시할 스타일입니다.

func _ready():
	# 기본 스타일 (투명)
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	custom_minimum_size = Vector2(160, 160)
	
	# 드롭 가능 스타일 (반투명 녹색)
	can_drop_stylebox = StyleBoxFlat.new()
	can_drop_stylebox.bg_color = Color(0.1, 1, 0.1, 0.3)
	can_drop_stylebox.border_width_left = 2
	can_drop_stylebox.border_width_right = 2
	can_drop_stylebox.border_width_top = 2
	can_drop_stylebox.border_width_bottom = 2
	can_drop_stylebox.border_color = Color.WHITE
	
	# 타입 불일치 스타일 (반투명 빨간색)
	type_mismatch_stylebox = StyleBoxFlat.new()
	type_mismatch_stylebox.bg_color = Color(1, 0.1, 0.1, 0.3)
	type_mismatch_stylebox.border_width_left = 2
	type_mismatch_stylebox.border_width_right = 2
	type_mismatch_stylebox.border_width_top = 2
	type_mismatch_stylebox.border_width_bottom = 2
	type_mismatch_stylebox.border_color = Color.RED
	
	add_theme_stylebox_override("panel", default_stylebox)
	clear_skill_display() # 시작할 때 빈 슬롯 UI로 초기화합니다.


# 드래그 중인 데이터가 이 슬롯에 드롭될 수 있는지 확인합니다.
func _can_drop_data(at_position, data) -> bool:
	# "skill" 타입의 데이터(인벤토리에서 온 스킬)만 받습니다.
	var can_drop = (data is Dictionary and data.has("type") and data.type == "skill")
	if not can_drop:
		return false # 장착 해제를 위해 드래그 중인 스킬("equipped_skill")은 받지 않습니다.
		
	# 드래그 중인 스킬의 타입과 슬롯의 타입이 일치하는지 확인합니다.
	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		# 타입이 일치하면 녹색 테두리를 표시합니다.
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true
	else:
		# 타입이 일치하지 않으면 빨간색 테두리를 표시합니다.
		add_theme_stylebox_override("panel", type_mismatch_stylebox)
		return true # 드롭 자체는 허용하되, 시각적으로만 실패를 알립니다. (실제 장착은 player.gd에서 최종적으로 막습니다.)


# 드래그가 끝나거나 마우스가 영역을 벗어나면 기본 스타일로 되돌립니다.
func _notification(what):
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		add_theme_stylebox_override("panel", default_stylebox)

# 데이터가 슬롯에 드롭되었을 때 실행됩니다.
func _drop_data(at_position, data):
	add_theme_stylebox_override("panel", default_stylebox)
	
	# 드롭 시점에 타입을 한 번 더 확인하고, 일치할 경우에만 장착 요청 시그널을 보냅니다.
	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		emit_signal("skill_dropped_on_slot", data.path, slot_index)
	else:
		print("UI: 타입 불일치로 장착이 거부되었습니다.")

# 장착된 스킬을 드래그하여 장착 해제할 수 있도록 드래그 데이터를 설정합니다.
func _get_drag_data(at_position):
	# 슬롯이 비어있지 않은지 아이콘 텍스처 유무로 확인합니다.
	if $VBoxContainer/Icon.texture != null:
		var drag_data = {
			"type": "equipped_skill", # 장착 해제용 데이터 타입입니다.
			"slot_index_from": slot_index
		}
		
		# 드래그 시 마우스 커서에 표시될 미리보기 이미지를 생성합니다.
		var preview = TextureRect.new()
		preview.texture = $VBoxContainer/Icon.texture
		preview.custom_minimum_size = Vector2(128, 128)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		set_drag_preview(preview)
		return drag_data
	
	return null # 빈 슬롯은 드래그할 수 없습니다.

# SkillUI.gd에서 이 슬롯의 UI를 업데이트하기 위해 호출하는 함수들입니다.
func set_skill_display(icon: Texture, name: String, description: String):
	$VBoxContainer/NameLabel.text = name
	$VBoxContainer/Icon.texture = icon
	self.tooltip_text = description

func clear_skill_display():
	$VBoxContainer/NameLabel.text = "[Slot " + str(slot_index) + "]"
	$VBoxContainer/Icon.texture = null
	self.tooltip_text = "비어있는 슬롯"