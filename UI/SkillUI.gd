# SkillUI.gd
extends CanvasLayer
class_name SkillUI

const SkillCard = preload("res://UI/SkillCard.gd")

#region Node References
@export var inventory_grid: GridContainer
@export var equipped_slot_1: Control
@export var equipped_slot_2: Control
@export var equipped_slot_3: Control
@export var inventory_drop_area: ScrollContainer
@export var tab_container: TabContainer

# Upgrade tab UI
@export var upgrade_base_slot: Control
@export var upgrade_material_slot: Control
@export var upgrade_button: Button
@export var upgrade_info_label: Label

# Synthesis tab UI
@export var synthesis_slot1: Control
@export var synthesis_slot2: Control
@export var synthesis_button: Button
@export var synthesis_info_label: Label
#endregion

#region [Simple Sound Settings]
@export_group("Sound Settings")
@export var sfx_player: AudioStreamPlayer
@export var sound_equip: AudioStream      
@export var sound_unequip: AudioStream    
@export var sound_success: AudioStream    
@export var sound_fail: AudioStream       
@export var sound_synthesis: AudioStream  
#endregion

var player_node_ref: CharacterBody2D

var current_upgrade_base: SkillInstance = null
var current_upgrade_material: SkillInstance = null
var current_synthesis_skill1: SkillInstance = null
var current_synthesis_skill2: SkillInstance = null

func _ready():
	if is_instance_valid(tab_container):
		tab_container.add_theme_font_size_override("font_size", 24)
	if is_instance_valid(upgrade_base_slot):
		upgrade_base_slot.slot_index = 10
	if is_instance_valid(upgrade_material_slot):
		upgrade_material_slot.slot_index = 11
	
	# Connect signals
	if is_instance_valid(equipped_slot_1) and equipped_slot_1.has_signal("skill_dropped_on_slot"):
		equipped_slot_1.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(equipped_slot_2) and equipped_slot_2.has_signal("skill_dropped_on_slot"):
		equipped_slot_2.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(equipped_slot_3) and equipped_slot_3.has_signal("skill_dropped_on_slot"):
		equipped_slot_3.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(inventory_drop_area):
		inventory_drop_area.skill_unequipped.connect(_on_skill_unequipped)
	if is_instance_valid(upgrade_base_slot) and upgrade_base_slot.has_signal("skill_dropped_on_slot"):
		upgrade_base_slot.skill_dropped_on_slot.connect(_on_upgrade_base_dropped)
	if is_instance_valid(upgrade_material_slot) and upgrade_material_slot.has_signal("skill_dropped_on_slot"):
		upgrade_material_slot.skill_dropped_on_slot.connect(_on_upgrade_material_dropped)
	if is_instance_valid(upgrade_button):
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	if is_instance_valid(synthesis_slot1) and synthesis_slot1.has_signal("skill_dropped_on_slot"):
		synthesis_slot1.skill_dropped_on_slot.connect(_on_synthesis_slot1_dropped)
	if is_instance_valid(synthesis_slot2) and synthesis_slot2.has_signal("skill_dropped_on_slot"):
		synthesis_slot2.skill_dropped_on_slot.connect(_on_synthesis_slot2_dropped)
	if is_instance_valid(synthesis_button):
		synthesis_button.pressed.connect(_on_synthesis_button_pressed)

#region [Sound] Helper Function
func play_sfx(stream: AudioStream):
	if sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.pitch_scale = randf_range(0.95, 1.05) 
		sfx_player.play()
#endregion

#region UI Management
func refresh_ui(player_node: CharacterBody2D):
	self.player_node_ref = player_node
	
	if is_instance_valid(inventory_grid):
		for child in inventory_grid.get_children():
			child.queue_free()
			
		var inventory_skills: Array[SkillInstance] = InventoryManager.player_inventory
		
		for skill_instance in inventory_skills:
			if skill_instance != current_upgrade_base and skill_instance != current_upgrade_material:
				var card = SkillCard.new()
				card.custom_minimum_size = Vector2(160, 160)
				card.skill_instance = skill_instance
				card.setup_card_ui()
				inventory_grid.add_child(card)
	
	if is_instance_valid(player_node):
		update_equip_slot_display(player_node.skill_1_slot, equipped_slot_1)
		update_equip_slot_display(player_node.skill_2_slot, equipped_slot_2)
		update_equip_slot_display(player_node.skill_3_slot, equipped_slot_3)
	
	refresh_upgrade_tab()
	refresh_synthesis_tab()

# Equipment tab
func update_equip_slot_display(player_skill_slot: Node, ui_equip_slot: Control):
	if not is_instance_valid(ui_equip_slot): return
	if not ui_equip_slot.has_method("set_skill_display"): return

	if player_skill_slot.get_child_count() > 0:
		var skill = player_skill_slot.get_child(0) as BaseSkill
		if skill:
			ui_equip_slot.set_skill_display(skill.skill_icon, skill.skill_name, skill.skill_description, skill.current_level)
	else:
		ui_equip_slot.clear_skill_display()
		

# Upgrade tab
func refresh_upgrade_tab():
	if is_instance_valid(upgrade_base_slot):
		if is_instance_valid(current_upgrade_base):
			var t = load(current_upgrade_base.skill_path).instantiate()
			upgrade_base_slot.set_skill_display(t.skill_icon, t.skill_name, t.skill_description, current_upgrade_base.level)
			t.queue_free()
		else:
			upgrade_base_slot.clear_skill_display()
			
	if is_instance_valid(upgrade_material_slot):
		if is_instance_valid(current_upgrade_material):
			var t = load(current_upgrade_material.skill_path).instantiate()
			upgrade_material_slot.set_skill_display(t.skill_icon, t.skill_name, t.skill_description, current_upgrade_material.level)
			t.queue_free()
		else:
			upgrade_material_slot.clear_skill_display()
			
	if is_instance_valid(upgrade_info_label):
		if is_instance_valid(current_upgrade_base):
			upgrade_info_label.text = "Current bonus: " + str(current_upgrade_base.bonus_points) + "%"
		else:
			upgrade_info_label.text = "Place a skill to upgrade."

# Synthesis tab
func refresh_synthesis_tab():
	if is_instance_valid(synthesis_slot1):
		if is_instance_valid(current_synthesis_skill1):
			var t = load(current_synthesis_skill1.skill_path).instantiate()
			synthesis_slot1.set_skill_display(t.skill_icon, t.skill_name, t.skill_description, current_synthesis_skill1.level)
			t.queue_free()
		else:
			synthesis_slot1.clear_skill_display()

	if is_instance_valid(synthesis_slot2):
		if is_instance_valid(current_synthesis_skill2):
			var t = load(current_synthesis_skill2.skill_path).instantiate()
			synthesis_slot2.set_skill_display(t.skill_icon, t.skill_name, t.skill_description, current_synthesis_skill2.level)
			t.queue_free()
		else:
			synthesis_slot2.clear_skill_display()

	if is_instance_valid(synthesis_info_label):
		if not is_instance_valid(current_synthesis_skill1) or not is_instance_valid(current_synthesis_skill2):
			synthesis_info_label.text = "Place 2 skills to use for synthesis."
		else:
			synthesis_info_label.text = "You can synthesize two skills to get a new skill."
#endregion

#region Signal Callbacks
# Equip skill
func _on_skill_dropped(skill_instance: SkillInstance, slot_index: int):
	print("Attempting to equip " + skill_instance.skill_path + " in slot " + str(slot_index) + "!")
	
	if player_node_ref:
		if InventoryManager.remove_skill_from_inventory(skill_instance):
			player_node_ref.equip_skill(skill_instance, slot_index)
			play_sfx(sound_equip) 
			get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
		else:
			print("UI error: Attempting to equip a skill not in inventory")

# Unequip skill
func _on_skill_unequipped(slot_index: int):
	var unequipped = false
	
	if slot_index >= 1 and slot_index <= 3:
		if player_node_ref:
			player_node_ref.unequip_skill(slot_index)
			unequipped = true

	elif slot_index == 10:
		if is_instance_valid(current_upgrade_base):
			current_upgrade_base = null
			unequipped = true

	elif slot_index == 11:
		if is_instance_valid(current_upgrade_material):
			current_upgrade_material = null
			unequipped = true

	elif slot_index == 12:
		if is_instance_valid(current_synthesis_skill1):
			InventoryManager.add_skill_to_inventory(current_synthesis_skill1)
			current_synthesis_skill1 = null
			unequipped = true

	elif slot_index == 13:
		if is_instance_valid(current_synthesis_skill2):
			InventoryManager.add_skill_to_inventory(current_synthesis_skill2)
			current_synthesis_skill2 = null
			unequipped = true

	if unequipped:
		play_sfx(sound_unequip) 

	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

# Upgrade target skill drop
func _on_upgrade_base_dropped(skill_instance: SkillInstance, slot_index: int):
	if is_instance_valid(current_upgrade_base):
		InventoryManager.add_skill_to_inventory(current_upgrade_base)
		
	current_upgrade_base = skill_instance
	play_sfx(sound_equip) 
	
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

# Upgrade material skill drop
func _on_upgrade_material_dropped(skill_instance: SkillInstance, slot_index: int):
	if is_instance_valid(current_upgrade_material):
		InventoryManager.add_skill_to_inventory(current_upgrade_material)
		
	current_upgrade_material = skill_instance
	play_sfx(sound_equip) 
	
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

# Upgrade button
func _on_upgrade_button_pressed():
	var success = InventoryManager.attempt_upgrade(current_upgrade_base, current_upgrade_material)
	
	if success:
		play_sfx(sound_success) 
		InventoryManager.remove_skill_from_inventory(current_upgrade_material)
		current_upgrade_material = null
	else:
		play_sfx(sound_fail)    
		InventoryManager.remove_skill_from_inventory(current_upgrade_material)
		current_upgrade_material = null
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

# Synthesis slot 1 drop
func _on_synthesis_slot1_dropped(skill_instance: SkillInstance, slot_index: int):
	if is_instance_valid(current_synthesis_skill1):
		InventoryManager.add_skill_to_inventory(current_synthesis_skill1)
	InventoryManager.remove_skill_from_inventory(skill_instance)
	current_synthesis_skill1 = skill_instance
	play_sfx(sound_equip) # [Sound]
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))


# Synthesis slot 2 drop
func _on_synthesis_slot2_dropped(skill_instance: SkillInstance, slot_index: int):
	if is_instance_valid(current_synthesis_skill2):
		InventoryManager.add_skill_to_inventory(current_synthesis_skill2)
	InventoryManager.remove_skill_from_inventory(skill_instance)
	current_synthesis_skill2 = skill_instance
	play_sfx(sound_equip) # [Sound]
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))

# Synthesis button
func _on_synthesis_button_pressed():
	if not is_instance_valid(current_synthesis_skill1) or not is_instance_valid(current_synthesis_skill2):
		print("Synthesis error: Insufficient materials.")
		play_sfx(sound_fail) # [Sound] 
		return
		
	var getSkill = InventoryManager.get_random_skill_path()
	InventoryManager.add_skill_to_inventory(getSkill)
	print("Skill synthesis success! " + getSkill + " acquired")
	
	play_sfx(sound_synthesis) # [Sound] 
	
	current_synthesis_skill1 = null
	current_synthesis_skill2 = null
	
	get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
#endregion
