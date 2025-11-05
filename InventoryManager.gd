# res://InventoryManager.gd
extends Node

# ★ 플레이어가 '소유'한 모든 스킬 씬(프리팹)의 경로
# (나중에 이 목록에 스킬을 추가/제거하면 됨)
var owned_skills: Array[String] = [
    "res://SkillDatas/Skill_Melee/Skill_Melee.tscn",
    "res://SkillDatas/Skill_BlinkSlash/Skill_BlinkSlash.tscn",
    "res://skills/parry/Skill_Parry.tscn"
]

# (나중에 여기에 플레이어가 '현재 장착'한 스킬 정보도 저장할 수 있음)