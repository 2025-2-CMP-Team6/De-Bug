# ui/SkillUI.gd
extends CanvasLayer

@onready var inventory_grid = $Panel/InventoryGrid
@onready var equipped_slots = $Panel/EquippedSlots

# 마우스를 올렸을 때 표시할 하얀색 테두리 스타일입니다.
var hover_stylebox: StyleBoxFlat
# 평상시에는 투명하게 유지할 기본 스타일입니다.
var default_stylebox: StyleBoxFlat

func _ready():
	# 마우스 호버 시 적용할 반투명한 하얀색 배경 스타일을 생성합니다.
	hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = Color(1, 1, 1, 0.15)
	hover_stylebox.corner_radius_top_left = 4
	hover_stylebox.corner_radius_top_right = 4
	hover_stylebox.corner_radius_bottom_left = 4
	hover_stylebox.corner_radius_bottom_right = 4

	# 평상시에 사용할 완전 투명 배경 스타일을 생성합니다.
	default_stylebox = StyleBoxFlat.new()
	default_stylebox.bg_color = Color(0, 0, 0, 0) # 완전 투명


# UI 새로고침
func refresh_ui(player_node: CharacterBody2D):
	# 1. 인벤토리(보유 스킬) 목록을 새로고침합니다.
	for child in inventory_grid.get_children():
		child.queue_free()
		
	var owned_skills_paths = InventoryManager.owned_skills

	for skill_path in owned_skills_paths:
		var skill_scene = load(skill_path)
		if skill_scene:
			var skill_instance = skill_scene.instantiate() as BaseSkill
			
			# 스킬 하나를 표시할 카드 UI(PanelContainer)를 생성합니다.
			var card = PanelContainer.new()
			card.custom_minimum_size = Vector2(160, 160)
			card.tooltip_text = skill_instance.skill_description
			
			# 카드의 기본 스타일을 투명으로 설정합니다.
			card.add_theme_stylebox_override("panel", default_stylebox)

			# 마우스 이벤트를 처리하기 위해 시그널을 연결합니다.
			card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
			card.mouse_exited.connect(_on_card_mouse_exited.bind(card))

			# 아이콘과 이름을 수직으로 정렬하기 위해 VBoxContainer를 추가합니다.
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			card.add_child(vbox) # PanelContainer는 자식을 하나만 가짐
			
			# 아이콘 (TextureRect)
			var icon = TextureRect.new()
			icon.texture = skill_instance.skill_icon
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(128, 128)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			
			# 이름 (Label)
			var name_label = Label.new()
			name_label.text = skill_instance.skill_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.custom_minimum_size = Vector2(160, 0)
			
			# VBox에 아이콘과 라벨 추가
			vbox.add_child(icon)
			vbox.add_child(name_label)
			
			inventory_grid.add_child(card)
			skill_instance.queue_free()
			
	
	# 2. 장착된 스킬 목록을 새로고침합니다.
	for child in equipped_slots.get_children():
		child.queue_free()
		
	add_equipped_skill_icon(player_node.skill_1_slot)
	add_equipped_skill_icon(player_node.skill_2_slot)
	add_equipped_skill_icon(player_node.skill_3_slot)


# 장착 슬롯 헬퍼 함수
func add_equipped_skill_icon(slot_node: Node):
	if slot_node.get_child_count() > 0:
		var skill = slot_node.get_child(0) as BaseSkill
		if skill:
			# PanelContainer를 '카드'로 사용
			var card = PanelContainer.new()
			card.custom_minimum_size = Vector2(160, 160)
			card.tooltip_text = skill.skill_description
			card.add_theme_stylebox_override("panel", default_stylebox) # 기본 투명

			# 마우스 시그널 연결
			card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
			card.mouse_exited.connect(_on_card_mouse_exited.bind(card))
			
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			card.add_child(vbox)
			
			var icon = TextureRect.new()
			icon.texture = skill.skill_icon
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(128, 128)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			
			var name_label = Label.new()
			name_label.text = skill.skill_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			vbox.add_child(icon)
			vbox.add_child(name_label)
			equipped_slots.add_child(card)
		else:
			add_empty_slot_ui()
	else:
		add_empty_slot_ui()

# 빈 슬롯 헬퍼 함수
func add_empty_slot_ui():
	var empty_slot = Control.new()
	empty_slot.custom_minimum_size = Vector2(160, 160)
	equipped_slots.add_child(empty_slot)


# --- 시그널 핸들러 ----------------------------------------------------

# 마우스가 카드 위로 올라왔을 때 호출됩니다.
func _on_card_mouse_entered(card: PanelContainer):
	# 카드의 "panel" 스타일을 마우스 호버 스타일로 변경합니다.
	card.add_theme_stylebox_override("panel", hover_stylebox)

# 마우스가 카드에서 벗어났을 때 호출됩니다.
func _on_card_mouse_exited(card: PanelContainer):
	# 카드의 "panel" 스타일을 다시 기본 투명 스타일로 되돌립니다.
	card.add_theme_stylebox_override("panel", default_stylebox)
