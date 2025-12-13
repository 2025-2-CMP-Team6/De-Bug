# EquipSlot.gd
extends PanelContainer

#region Variables and Signals
@export var slot_index: int = 1

signal skill_dropped_on_slot(skill_instance: SkillInstance, slot_index: int)

var default_stylebox: StyleBoxFlat
var can_drop_stylebox: StyleBoxFlat
var type_mismatch_stylebox: StyleBoxFlat
var hover_stylebox: StyleBoxFlat

# Node References
@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel

# Data for tooltip display
var _tooltip_name: String = ""
var _tooltip_desc: String = ""
var _tooltip_level: int = 0
var _tooltip_icon: Texture = null
#endregion
# UI/EquipSlot.gd

func _ready():
	# Default style
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0.5)
	default_stylebox.set_border_width_all(1)
	default_stylebox.border_color = Color(1, 1, 1, 0.2)
	default_stylebox.set_corner_radius_all(4)

	# Hover style
	hover_stylebox = default_stylebox.duplicate()
	hover_stylebox.set_border_width_all(1) # Border width 3px
	hover_stylebox.border_color = Color.WHITE # Completely white

	# Drop allowed style
	can_drop_stylebox = StyleBoxFlat.new()
	can_drop_stylebox.bg_color = Color(0.1, 1, 0.1, 0.2)
	can_drop_stylebox.set_border_width_all(2)
	can_drop_stylebox.border_color = Color(0.5, 1, 0.5)
	can_drop_stylebox.set_corner_radius_all(4)

	# Mismatch style
	type_mismatch_stylebox = StyleBoxFlat.new()
	type_mismatch_stylebox.bg_color = Color(1, 0.1, 0.1, 0.2)
	type_mismatch_stylebox.set_border_width_all(2)
	type_mismatch_stylebox.border_color = Color(1, 0.5, 0.5)
	type_mismatch_stylebox.set_corner_radius_all(4)

	custom_minimum_size = Vector2(160, 160)
	add_theme_stylebox_override("panel", default_stylebox)
	
	if is_instance_valid(icon_rect):
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		icon_rect.custom_minimum_size = Vector2(64, 64)

	# Connect mouse events
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
		
	clear_skill_display()

#region Hover Effects
# Hover start
func _on_mouse_entered():
	if get_viewport().gui_is_dragging(): return
	add_theme_stylebox_override("panel", hover_stylebox)

# Hover end
func _on_mouse_exited():
	if get_viewport().gui_is_dragging(): return
	add_theme_stylebox_override("panel", default_stylebox)
#endregion


#region Drag and Drop
func _can_drop_data(at_position, data) -> bool:
	var can_drop = (data is Dictionary and data.has("type") and data.type == "skill_instance")
	if not can_drop:
		return false
	if slot_index == 0 or slot_index == 10 or slot_index == 12 or slot_index == 13: # Upgrade target slot, synthesis slot
		add_theme_stylebox_override("panel", can_drop_stylebox)
		return true
	if slot_index == 11: # Upgrade material slot
		var skill_ui = get_tree().get_first_node_in_group("skill_ui")
		if not is_instance_valid(skill_ui) or not is_instance_valid(skill_ui.current_upgrade_base):
			return false

		# Path must be the same and not itself
		var is_same_path = (skill_ui.current_upgrade_base.skill_path == data.instance.skill_path)
		var is_not_self = (skill_ui.current_upgrade_base != data.instance)
		
		if is_same_path and is_not_self:
			add_theme_stylebox_override("panel", can_drop_stylebox)
			return true
		else:
			add_theme_stylebox_override("panel", type_mismatch_stylebox)
			return true

	if data.has("skill_type_int") and data.skill_type_int == slot_index: # Skill equip slot
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
		print("UI: Equip rejected due to condition mismatch (red)")
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

#region Tooltip
func _make_custom_tooltip(_for_text):
	# Use default text tooltip if no skill info
	if _tooltip_name == "":
		return null

	var scene = load("res://UI/SkillSelect.tscn")
	if not scene:
		return null
		
	var tooltip = scene.instantiate()
	
	var icon_node = tooltip.get_node_or_null("icon")
	var name_node = tooltip.get_node_or_null("name")
	var text_node = tooltip.get_node_or_null("text")
	
	if icon_node:
		if icon_node is TextureRect:
			icon_node.texture = _tooltip_icon
			icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		elif icon_node is Sprite2D:
			icon_node.texture = _tooltip_icon
			
	if name_node is Label:
		if _tooltip_level > 0:
			name_node.text = _tooltip_name + " + " + str(_tooltip_level)
		else:
			name_node.text = _tooltip_name
			
	if text_node is Label:
		text_node.text = _tooltip_desc
		
	return tooltip
#endregion

#region UI Update
func set_skill_display(icon: Texture, name: String, description: String, level: int = 0):
	if level > 0:
		name_label.text = name + " + " + str(level)
	else:
		name_label.text = name
		
	icon_rect.texture = icon
	
	_tooltip_name = name
	_tooltip_desc = description
	_tooltip_level = level
	_tooltip_icon = icon
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
	
	_tooltip_name = ""
	_tooltip_desc = ""
	_tooltip_level = 0
	_tooltip_icon = null
	self.tooltip_text = "Empty slot"
#endregion
