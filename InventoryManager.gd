# res://InventoryManager.gd
extends Node

# 스킬 프리팹(.tscn)이 저장된 메인 폴더 경로입니다.
const SKILL_DIRECTORY = "res://SkillDatas/"

# `skill_database`: 게임에 존재하는 모든 스킬의 전체 목록입니다.
var skill_database: Array[String] = []

# `player_inventory`: 플레이어가 현재 소유한 (장착하지 않은) 스킬 목록입니다.
# 동일한 스킬을 여러 개 소유할 수 있습니다.
var player_inventory: Array[String] = []

# 현재 장착된 스킬의 경로를 슬롯 번호에 따라 저장합니다.
var equipped_skill_paths: Dictionary = {
	1: null,
	2: null,
	3: null
}

func _ready():
	print("InventoryManager: " + SKILL_DIRECTORY + " 폴더에서 스킬을 스캔합니다...")
	load_skills_from_directory(SKILL_DIRECTORY)
	print("스킬 DB 로드 완료! 총 " + str(skill_database.size()) + "개 발견됨")
	
	# 테스트를 위해 플레이어 인벤토리에 기본 스킬을 추가합니다.
	# 실제 게임에서는 게임 시작 시점이나 스킬 획득 시점에 호출해야 합니다.
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Melee/Skill_Melee.tscn") # 2개 추가
	add_skill_to_inventory("res://SkillDatas/Skill_BlinkSlash/Skill_BlinkSlash.tscn")
	add_skill_to_inventory("res://SkillDatas/Skill_Parry/Skill_Parry.tscn")

# 플레이어 인벤토리에 스킬을 추가합니다.
func add_skill_to_inventory(skill_path: String):
	# TODO: skill_database에 존재하는 유효한 스킬인지 검증하는 로직을 추가하면 더 안정적입니다.
	player_inventory.append(skill_path)
	print(skill_path + "가 인벤토리에 추가됨.")

# 플레이어 인벤토리에서 지정된 스킬을 하나 제거합니다.
func remove_skill_from_inventory(skill_path: String) -> bool:
	var index = player_inventory.find(skill_path)
	if index != -1: # 인벤토리에서 스킬을 찾았을 경우
		player_inventory.pop_at(index)
		print(skill_path + "가 인벤토리에서 제거됨.")
		return true
	
	print("오류: " + skill_path + "가 인벤토리에 없음!")
	return false

# 지정된 `path`와 그 하위 폴더들을 재귀적으로 탐색하여 .tscn 파일을 찾습니다.
func load_skills_from_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			if dir.current_is_dir():
				load_skills_from_directory(path + file_name + "/")
			else:
				if file_name.ends_with(".tscn"):
					# 발견된 스킬 씬 파일의 전체 경로를 데이터베이스에 추가합니다.
					skill_database.append(path + file_name)
			file_name = dir.get_next()
	else:
		print("오류: 스킬 폴더(" + path + ")를 열 수 없습니다!")