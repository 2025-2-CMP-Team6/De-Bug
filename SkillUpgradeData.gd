# res://SkillUpgradeData.gd
extends Resource
class_name SkillUpgradeData

# 1. 'Variable name' of the stat to change (e.g., "damage", "cooldown")
@export var stat_name: StringName

# 2. Array of values to be applied per level (level 0, level 1, level 2...)
@export var stat_values_by_level: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
