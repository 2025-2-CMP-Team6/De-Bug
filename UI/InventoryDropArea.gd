# ui/InventoryDropArea.gd
extends ScrollContainer

signal skill_unequipped(slot_index: int)

# Whether skill can be equipped
func _can_drop_data(_at_position, data) -> bool:
	return (data is Dictionary and data.has("type") and data.type == "equipped_skill")

# Called when mouse is released
func _drop_data(_at_position, data):
	print("Unequip drop detected: slot #" + str(data.slot_index_from))
	emit_signal("skill_unequipped", data.slot_index_from)
