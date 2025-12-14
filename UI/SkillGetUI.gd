extends CanvasLayer
class_name SkillGetUI

#region Signals
signal closed
#endregion

#region Node References
@export var skill_select1: Panel
@export var skill_select2: Panel
@export var skill_select3: Panel
@export var select_button: Button
@export var background_panel: Panel
@export var cancel_button: Button
#endregion

# Storage for currently selected skill data and UI node
var selected_skill_instance: SkillInstance = null
var selected_slot_node: Panel = null

# Variables for storing the slot's original state (parent, position)
var original_parent: Node = null
var original_sibling_index: int = -1

# Track animation playback state
var is_animating: bool = false

# Color settings for visual effects
const COLOR_NORMAL = Color(1, 1, 1, 1) # Normal
const COLOR_HOVER = Color(1.1, 1.1, 1.1, 1) # Hover
const COLOR_SELECTED = Color(1.5, 1.5, 1.5, 1) # Selected

func _ready() -> void:
	visible = false
	
	if is_instance_valid(cancel_button):
		cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	if is_instance_valid(select_button):
		select_button.pressed.connect(_on_select_button_pressed)
		select_button.disabled = true # Initially disabled to prevent selection

#region Animation
func open_reward_screen() -> void:
	if is_animating or visible: return # Prevent opening during animation
	is_animating = true
	
	_reset_selection()
	_generate_rewards()

	# Restore the state of buttons (position, transparency, activation) back to original.
	if is_instance_valid(select_button):
		select_button.modulate = COLOR_NORMAL
	if is_instance_valid(cancel_button):
		cancel_button.modulate = COLOR_NORMAL
		cancel_button.disabled = false

	# Reset the background panel state completely.
	if is_instance_valid(background_panel):
		background_panel.modulate = COLOR_NORMAL
		background_panel.position = Vector2(654, 321)
	# Reset the position, size, and transparency of each slot completely.
	var slots = [skill_select1, skill_select2, skill_select3]
	for slot in slots:
		if is_instance_valid(slot):
			slot.scale = Vector2.ZERO
			slot.modulate = COLOR_NORMAL # Reset entire color including alpha value (most important)
			slot.position = Vector2.ZERO # Reset entire position, not just y

	var screen_height = get_viewport().get_visible_rect().size.y
	self.offset.y = - screen_height
	visible = true
	call_deferred("_start_open_animation")
# Open animation
func _start_open_animation():
	var tween = create_tween()
	tween.set_parallel(false)

	# Set is_animating to false when open animation finishes
	tween.finished.connect(func(): is_animating = false)
	tween.tween_property(self, "offset:y", 0.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	var slots = [skill_select1, skill_select2, skill_select3]
	for slot in slots:
		if is_instance_valid(slot):
			var has_skill = false
			for child in slot.get_children():
				if child is Button:
					has_skill = true
					break
			
			if has_skill:
				tween.tween_property(slot, "scale", Vector2.ONE, 0.15).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reset_selection():
	selected_skill_instance = null
	selected_slot_node = null
	if is_instance_valid(select_button):
		select_button.disabled = true # Disable button

func _generate_rewards():
	var all_db_skills = InventoryManager.skill_database
	var unique_skills: Array[String] = []
	for skill_path in all_db_skills:
		if not skill_path in unique_skills:
			unique_skills.append(skill_path)

	var chosen_skills: Array[String] = []
	if unique_skills.size() <= 3:
		chosen_skills = unique_skills
	else:
		unique_skills.shuffle()
		chosen_skills = unique_skills.slice(0, 3)
	
	_setup_slot(skill_select1, chosen_skills[0] if chosen_skills.size() > 0 else "")
	_setup_slot(skill_select2, chosen_skills[1] if chosen_skills.size() > 1 else "")
	_setup_slot(skill_select3, chosen_skills[2] if chosen_skills.size() > 2 else "")

func _setup_slot(slot_node: Panel, skill_path: String):
	if not is_instance_valid(slot_node): return

	var old_button = slot_node.get_node_or_null("ClickButton")
	if is_instance_valid(old_button):
		old_button.queue_free()
	
	slot_node.modulate = COLOR_NORMAL
	var icon_node = slot_node.get_node_or_null("icon")
	var name_node = slot_node.get_node_or_null("name")
	var type_node = slot_node.get_node_or_null("type")
	var text_node = slot_node.get_node_or_null("text")
	
	if icon_node is TextureRect: icon_node.texture = null
	if icon_node is Sprite2D: icon_node.texture = null
	if name_node is Label: name_node.text = ""
	if text_node is Label: text_node.text = ""
	
	if skill_path == "":
		slot_node.visible = false
		return
	
	slot_node.visible = true
	var skill_scene = load(skill_path)
	if not skill_scene: return
	var temp_skill = skill_scene.instantiate() as BaseSkill
	if not is_instance_valid(temp_skill): return

	if icon_node:
		var desired_icon_size = Vector2(128, 128) # Adjust value if needed

		if icon_node is TextureRect:
			icon_node.texture = temp_skill.skill_icon
			icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_node.custom_minimum_size = desired_icon_size
		elif icon_node is Sprite2D:
			icon_node.texture = temp_skill.skill_icon
			if temp_skill.skill_icon != null:
				var tex_size = temp_skill.skill_icon.get_size()
				if tex_size.x > 0 and tex_size.y > 0:
					var sx = desired_icon_size.x / float(tex_size.x)
					var sy = desired_icon_size.y / float(tex_size.y)
					var s = min(sx, sy)
					icon_node.scale = Vector2(s, s)
				else:
					icon_node.scale = Vector2.ONE
			else:
				icon_node.scale = Vector2.ONE
	if name_node and name_node is Label:
		name_node.text = temp_skill.skill_name
	if type_node and type_node is Label:
		var type_text = ""
		for i in range(temp_skill.type):
			type_text += "I"
		type_node.text = type_text
	if text_node and text_node is Label:
		text_node.text = temp_skill.skill_description

	# 4. Create new data and button and connect them.
	var instance = SkillInstance.new()
	instance.skill_path = skill_path
	instance.level = 0
	
	var btn = SkillTooltipButton.new()
	btn.name = "ClickButton" # Set name to identify the button
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.modulate.a = 0.0
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	btn.pressed.connect(_on_slot_clicked.bind(instance, slot_node))
	btn.mouse_entered.connect(_on_slot_mouse_entered.bind(slot_node))
	btn.mouse_exited.connect(_on_slot_mouse_exited.bind(slot_node))

	# Set tooltip data
	btn.skill_name = temp_skill.skill_name
	btn.skill_desc = temp_skill.skill_description
	btn.skill_icon = temp_skill.skill_icon
	btn.tooltip_text = temp_skill.skill_description
	
	slot_node.add_child(btn)

	temp_skill.queue_free()
#region Event Handlers
# Slot Click
func _on_slot_clicked(skill_instance: SkillInstance, slot_node: Control): # Panel -> Control
	selected_skill_instance = skill_instance
	selected_slot_node = slot_node
	
	_update_visuals()
	
	if is_instance_valid(select_button):
		select_button.disabled = false

# Mouse Hover
func _on_slot_mouse_entered(slot_node: Control):
	if slot_node != selected_slot_node:
		if slot_node.has_meta("hover_tween"):
			var t = slot_node.get_meta("hover_tween") as Tween
			if t and t.is_valid(): t.kill()
			
		var tween = create_tween()
		slot_node.set_meta("hover_tween", tween)
		
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

		# 3. Property changes
		tween.tween_property(slot_node, "scale", Vector2(1.05, 1.05), 0.15)
		tween.tween_property(slot_node, "modulate", COLOR_HOVER, 0.15)
		print("Mouse hover: " + str(slot_node))

# Mouse Hover Exit
func _on_slot_mouse_exited(slot_node: Control):
	if slot_node != selected_slot_node:
		if slot_node.has_meta("hover_tween"):
			var t = slot_node.get_meta("hover_tween") as Tween
			if t and t.is_valid(): t.kill()
			
		var tween = create_tween()
		slot_node.set_meta("hover_tween", tween)
		
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(slot_node, "scale", Vector2(1.0, 1.0), 0.15)
		tween.tween_property(slot_node, "modulate", COLOR_NORMAL, 0.15)

# Button Click
func _on_select_button_pressed():
	if is_animating: return # Prevent action during animation
	is_animating = true
	
	if selected_skill_instance == null: return

	print("Skill confirmed acquired: " + selected_skill_instance.skill_path)
	InventoryManager.add_skill_to_inventory(selected_skill_instance)
	
	var skill_ui = get_tree().get_first_node_in_group("skill_ui")
	if is_instance_valid(skill_ui) and skill_ui.has_method("refresh_ui"):
		var player = get_tree().get_first_node_in_group("player")
		if player: skill_ui.refresh_ui(player)
		
	_start_close_animation(selected_skill_instance, selected_slot_node)

func _on_cancel_button_pressed():
	if is_animating: return # Prevent action during animation
	is_animating = true

	print("Reward skipped")
	_start_close_animation(null, null)
#endregion

# Batch update visual effects
func _update_visuals():
	var slots = [skill_select1, skill_select2, skill_select3]
	for slot in slots:
		if not is_instance_valid(slot): continue

		# Clean up existing tween
		if slot.has_meta("select_tween"):
			var t = slot.get_meta("select_tween") as Tween
			if t and t.is_valid(): t.kill()
			
		var tween = create_tween()
		slot.set_meta("select_tween", tween)
		tween.set_parallel(true)

		if slot == selected_slot_node:
			# Selected slot
			tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.2) # 10% zoom
			tween.tween_property(slot, "modulate", COLOR_SELECTED, 0.2)
		else:
			# Unselected slot
			tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.2)
			tween.tween_property(slot, "modulate", COLOR_NORMAL, 0.2)

# Start close window animation
func _start_close_animation(selected_instance: SkillInstance, selected_slot: Panel):
	self.offset.y = 0
	
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var screen_height = get_viewport().get_visible_rect().size.y
	var slots = [skill_select1, skill_select2, skill_select3]

	var fall_tween = create_tween().set_parallel(true)

	# Disable buttons and add animation
	if is_instance_valid(select_button):
		select_button.disabled = true
		fall_tween.tween_property(select_button, "modulate:a", 0.0, 0.3)
	if is_instance_valid(cancel_button):
		cancel_button.disabled = true
		fall_tween.tween_property(cancel_button, "modulate:a", 0.0, 0.3)

	# Animate direct children of this node to fall together
	for child in get_children():
		if child is Panel and not child in slots:
			fall_tween.tween_property(child, "position:y", child.position.y + screen_height, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall_tween.tween_property(child, "modulate:a", 0.0, 0.4)

	for slot in slots:
		if slot != selected_slot and is_instance_valid(slot):
			# Unselected slots move down and fade out
			fall_tween.tween_property(slot, "position:y", slot.position.y + screen_height, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall_tween.tween_property(slot, "modulate:a", 0.0, 0.4)

	await fall_tween.finished
	if selected_instance == null:
		close_reward_screen()
		return

	# Save original parent and position (index) for reparenting
	original_parent = selected_slot.get_parent()
	original_sibling_index = selected_slot.get_index()

	var original_global_pos = selected_slot.global_position
	original_parent.remove_child(selected_slot)
	add_child(selected_slot)
	selected_slot.global_position = original_global_pos

	var target_global_pos = screen_center - selected_slot.size * selected_slot.scale / 2.0
	var move_tween = create_tween()
	move_tween.tween_property(selected_slot, "global_position", target_global_pos, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await move_tween.finished

	var exit_tween = create_tween().set_parallel(true)
	exit_tween.tween_property(selected_slot, "scale", Vector2(1.5, 1.5), 0.5)
	exit_tween.tween_property(selected_slot, "modulate:a", 0.0, 0.5)
	
	await exit_tween.finished

	close_reward_screen()

func close_reward_screen():
	# If reparenting occurred, restore node to original parent and position
	if is_instance_valid(selected_slot_node) and is_instance_valid(original_parent):
		if selected_slot_node.get_parent() == self:
			remove_child(selected_slot_node)
			original_parent.add_child(selected_slot_node)
			original_parent.move_child(selected_slot_node, original_sibling_index)
		# Reset reference
		original_parent = null

	visible = false
	closed.emit()
	is_animating = false # Reset state after all animations and cleanup are finished

#region Button Class for Tooltip
class SkillTooltipButton extends Button:
	var skill_name: String = ""
	var skill_desc: String = ""
	var skill_icon: Texture = null
	
	func _make_custom_tooltip(_for_text):
		var scene = load("res://UI/SkillTooltip.tscn")
		if not scene: return null
		
		var tooltip = scene.instantiate()
		
		var icon_node = tooltip.get_node_or_null("icon")
		var name_node = tooltip.get_node_or_null("name")
		var text_node = tooltip.get_node_or_null("text")
		
		if icon_node:
			if icon_node is TextureRect:
				icon_node.texture = skill_icon
				icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			elif icon_node is Sprite2D:
				icon_node.texture = skill_icon
				
		if name_node is Label:
			name_node.text = skill_name
			
		if text_node is Label:
			text_node.text = skill_desc
			
		return tooltip
#endregion
