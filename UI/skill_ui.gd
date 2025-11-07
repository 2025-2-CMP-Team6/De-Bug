# ui/SkillUI.gd
extends CanvasLayer

const SkillCard = preload("res://UI/SkillCard.gd")

@onready var inventory_grid = $Panel/ScrollContainer/InventoryGrid
@onready var equipped_slot_1 = $Panel/EquippedSlots/Slot1
@onready var equipped_slot_2 = $Panel/EquippedSlots/Slot2
@onready var equipped_slot_3 = $Panel/EquippedSlots/Slot3
@onready var inventory_drop_area = $Panel/ScrollContainer

var player_node_ref: CharacterBody2D

func _ready():
	equipped_slot_1.skill_dropped_on_slot.connect(_on_skill_dropped)
	equipped_slot_2.skill_dropped_on_slot.connect(_on_skill_dropped)
	equipped_slot_3.skill_dropped_on_slot.connect(_on_skill_dropped)
	inventory_drop_area.skill_unequipped.connect(_on_skill_unequipped)

# 전체 스킬 UI(인벤토리, 장착 슬롯)를 새로고침합니다.
func refresh_ui(player_node: CharacterBody2D):
	self.player_node_ref = player_node
	
	# 인벤토리(보유 스킬) 목록을 다시 그립니다.
	for child in inventory_grid.get_children():
		child.queue_free()
		
	# 전체 스킬 DB가 아닌, 플레이어가 실제 소유한 스킬 목록을 가져옵니다.
	var inventory_skills = InventoryManager.player_inventory

	for skill_path in inventory_skills:
		# player_inventory는 장착되지 않은 스킬만 포함하므로 별도 필터링이 필요 없습니다.
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
			
	
	# 장착된 스킬 슬롯의 UI 표시를 업데이트합니다.
	update_equip_slot_display(player_node.skill_1_slot, equipped_slot_1)
	update_equip_slot_display(player_node.skill_2_slot, equipped_slot_2)
	update_equip_slot_display(player_node.skill_3_slot, equipped_slot_3)


func update_equip_slot_display(player_skill_slot: Node, ui_equip_slot: PanelContainer):
	if player_skill_slot.get_child_count() > 0:
		var skill = player_skill_slot.get_child(0) as BaseSkill
		if skill:
			ui_equip_slot.set_skill_display(skill.skill_icon, skill.skill_name, skill.skill_description)
	else:
		ui_equip_slot.clear_skill_display()

# 스킬 카드를 장착 슬롯에 드롭했을 때 호출됩니다.
func _on_skill_dropped(skill_path: String, slot_index: int):
	print(str(slot_index) + "번 슬롯에 " + skill_path + " 장착 시도!")
	
	if player_node_ref:
		# 1. 인벤토리에서 해당 스킬을 먼저 제거합니다. 실패하면 장착 로직을 중단합니다.
		if InventoryManager.remove_skill_from_inventory(skill_path):
			# 2. 인벤토리에서 성공적으로 제거되면, 플레이어에게 스킬 장착을 요청합니다.
			player_node_ref.equip_skill(skill_path, slot_index)
			# 3. 잠시 후 UI를 새로고침하여 변경사항을 반영합니다.
			get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))
		else:
			print("UI 오류: 인벤토리에 없는 스킬을 장착 시도함")


# 장착된 스킬을 인벤토리 영역으로 드롭하여 장착 해제했을 때 호출됩니다.
func _on_skill_unequipped(slot_index: int):
	if player_node_ref:
		# player.gd의 unequip_skill 함수가 인벤토리 복귀를 포함한 모든 로직을 처리합니다.
		player_node_ref.unequip_skill(slot_index)
		get_tree().create_timer(0.01).timeout.connect(refresh_ui.bind(player_node_ref))