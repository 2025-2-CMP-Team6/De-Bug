# SkillUI.gd
extends CanvasLayer
class_name SkillUI

const SkillCard = preload("res://UI/SkillCard.gd")

#region 노드 참조
@export var inventory_grid: GridContainer
@export var equipped_slot_1: PanelContainer
@export var equipped_slot_2: PanelContainer
@export var equipped_slot_3: PanelContainer
@export var inventory_drop_area: ScrollContainer
@export var tab_container: TabContainer
#endregion

var player_node_ref: CharacterBody2D

func _ready():
	if is_instance_valid(tab_container):
		tab_container.add_theme_font_size_override("font_size", 24)

	if is_instance_valid(equipped_slot_1):
		equipped_slot_1.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(equipped_slot_2):
		equipped_slot_2.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(equipped_slot_3):
		equipped_slot_3.skill_dropped_on_slot.connect(_on_skill_dropped)
	if is_instance_valid(inventory_drop_area):
		inventory_drop_area.skill_unequipped.connect(_on_skill_unequipped)

#region UI 관리
func refresh_ui(player_node: CharacterBody2D):
	self.player_node_ref = player_node
	
	# --- 1. 인벤토리 UI 새로고침 (항상 보임) ---
	if is_instance_valid(inventory_grid):
		for child in inventory_grid.get_children():
			child.queue_free()
			
		var inventory_skills = InventoryManager.player_inventory
		# 인벤토리 스킬 카드 생성
		for skill_path in inventory_skills:
			var skill_scene = load(skill_path)
			if skill_scene:
				var skill_instance = skill_scene.instantiate() as BaseSkill
				
				var card = SkillCard.new()
				card.custom_minimum_size = Vector2(160, 160)
				
				card.skill_path = skill_path
				card.skill_icon = skill_instance.skill_icon
				card.skill_name = skill_instance.skill_name
				card.skill_description = skill_instance.skill_description
				card.skill_type = skill_instance.type
				
				card.setup_card_ui()
				
				inventory_grid.add_child(card)
				skill_instance.queue_free()
			
	
	# --- 2. 장착 슬롯 UI 새로고침 ("장착" 탭) ---
	if is_instance_valid(player_node):
		update_equip_slot_display(player_node.skill_1_slot, equipped_slot_1)
		update_equip_slot_display(player_node.skill_2_slot, equipped_slot_2)
		update_equip_slot_display(player_node.skill_3_slot, equipped_slot_3)

func update_equip_slot_display(player_skill_slot: Node, ui_equip_slot: PanelContainer):
	if not is_instance_valid(ui_equip_slot): return
	
	if player_skill_slot.get_child_count() > 0:
		var skill = player_skill_slot.get_child(0) as BaseSkill
		if skill:
			ui_equip_slot.set_skill_display(skill.skill_icon, skill.skill_name, skill.skill_description)
	else:
		ui_equip_slot.clear_skill_display()
#endregion

#region 시그널 콜백
func _on_skill_dropped(skill_path: String, slot_index: int):
	print(str(slot_index) + "번 슬롯에 " + skill_path + " 장착 시도!")
	
	if player_node_ref:
		if InventoryManager.remove_skill_from_inventory(skill_path):
			player_node_ref.equip_skill(skill_path, slot_index)
			get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
		else:
			print("UI 오류: 인벤토리에 없는 스킬을 장착 시도함")

func _on_skill_unequipped(slot_index: int):
	if player_node_ref:
		player_node_ref.unequip_skill(slot_index)
		get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
#endregion
