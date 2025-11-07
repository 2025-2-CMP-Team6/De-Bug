# ui/InventoryDropArea.gd
extends ScrollContainer

# "이 슬롯을 비워줘!"라고 SkillUI에게 알림
signal skill_unequipped(slot_index: int)

# 드래그 중인 데이터가 이 영역에 드롭될 수 있는지 확인
func _can_drop_data(_at_position, data) -> bool:
	# "equipped_skill" (이미 장착된 스킬) 타입만 받음
	return (data is Dictionary and data.has("type") and data.type == "equipped_skill")

# 마우스 버튼을 놓았을 때 '드롭' 실행
func _drop_data(_at_position, data):
	print("장착 해제 드롭 감지: " + str(data.slot_index_from) + "번 슬롯")
	emit_signal("skill_unequipped", data.slot_index_from)