# EquipSlot.gd
extends PanelContainer

#region 변수 및 시그널
@export var slot_index: int = 1

signal skill_dropped_on_slot(skill_instance: SkillInstance, slot_index: int)

var default_stylebox: StyleBoxFlat
var can_drop_stylebox: StyleBoxFlat
var type_mismatch_stylebox: StyleBoxFlat

# 노드 참조
@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
#endregion

func _ready():
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0)
	custom_minimum_size = Vector2(160, 160)
	can_drop_stylebox = StyleBoxFlat.new()
	can_drop_stylebox.bg_color = Color(0.1, 1, 0.1, 0.3)
	can_drop_stylebox.set_border_width_all(2)
	can_drop_stylebox.border_color = Color.WHITE
	type_mismatch_stylebox = StyleBoxFlat.new()
	type_mismatch_stylebox.bg_color = Color(1, 0.1, 0.1, 0.3)
	type_mismatch_stylebox.set_border_width_all(2)
	type_mismatch_stylebox.border_color = Color.RED
	add_theme_stylebox_override("panel", default_stylebox)
	
	if is_instance_valid(icon_rect):
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	clear_skill_display()


#region 드래그 앤 드롭
func _can_drop_data(at_position, data) -> bool:
	var can_drop = (data is Dictionary and data.has("type") and data.type == "skill_instance")
	if not can_drop:
		return false
	if slot_index == 0 or slot_index == 10 or slot_index == 12 or slot_index == 13: # 강화 대상 슬롯, 합성 슬롯
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true
	if slot_index == 11: # 강화 재료 슬롯
		var skill_ui = get_tree().get_first_node_in_group("skill_ui")
		if not is_instance_valid(skill_ui) or not is_instance_valid(skill_ui.current_upgrade_base):
			return false
		
		# 경로가 같고 자기 자신이 아니어야 함
		var is_same_path = (skill_ui.current_upgrade_base.skill_path == data.instance.skill_path)
		var is_not_self = (skill_ui.current_upgrade_base != data.instance)
		
		if is_same_path and is_not_self:
			add_theme_stylebox_override("panel", can_drop_stylebox)
			return true
		else:
			add_theme_stylebox_override("panel", type_mismatch_stylebox)
			return true

	if data.has("skill_type_int") and data.skill_type_int == slot_index: # 스킬 장착 슬롯
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true
	else:
		add_theme_stylebox_override("panel", type_mismatch_stylebox)
		return true

func _notification(what):
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		add_theme_stylebox_override("panel", default_stylebox)

func _drop_data(at_position, data):
	var current_style = get_theme_stylebox("panel")
	
	add_theme_stylebox_override("panel", default_stylebox)
	
	if current_style == type_mismatch_stylebox:
		print("UI: 조건 불일치(빨간색)로 장착 거부됨")
		return

	if slot_index == 0 or slot_index >= 10:
		emit_signal("skill_dropped_on_slot", data.instance, slot_index)
		return

	if data.has("skill_type_int") and data.skill_type_int == slot_index:
		emit_signal("skill_dropped_on_slot", data.instance, slot_index)
		
func _get_drag_data(at_position):
	if $VBoxContainer/Icon.texture != null:
		var drag_data = {
			"type": "equipped_skill",
			"slot_index_from": slot_index
		}
		var preview = TextureRect.new()
		preview.texture = $VBoxContainer/Icon.texture
		preview.custom_minimum_size = Vector2(128, 128)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_SCALE
		set_drag_preview(preview)
		return drag_data
	
	return null
#endregion

#region UI 업데이트
func set_skill_display(icon: Texture, name: String, description: String, level: int = 0):
	if level > 0:
		name_label.text = name + " + " + str(level)
	else:
		name_label.text = name
		
	icon_rect.texture = icon
	self.tooltip_text = description

func clear_skill_display():
	var display_text = ""
	match slot_index:
		10:
			display_text = "Upgrade Skill"
		11:
			display_text = "Material Skill"
		12:
			display_text = "Synthesis Skill"
		13:
			display_text = "Synthesis Skill"
		_:
			display_text = "[Slot " + str(slot_index) + "]"
	name_label.text = display_text
	icon_rect.texture = null
	self.tooltip_text = "비어있는 슬롯"
#endregion
