# res://SkillInstance.gd
extends Resource
class_name SkillInstance

# Path to this skill's original .tscn file
@export var skill_path: String

# Current skill level
@export var level: int = 0

# Current accumulated upgrade bonus probability (e.g., 10.0 = 10%)
@export var bonus_points: float = 0.0
