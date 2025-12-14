# BaseSkill.gd
extends Node
class_name BaseSkill

#region Skill Properties
@export var skill_name: String = "기본 스킬"
@export var skill_description: String = "스킬 설명."
@export var skill_icon: Texture
@export var cast_duration: float = 0.3
@export var stamina_cost: float = 10.0
@export var cooldown: float = 1.0
@export var type: int = 1
@export var requires_target: bool = false
@export var ends_on_condition: bool = false
@export var damage: float = 10.0
@export var max_cast_range: float = 0.0
@export var gravity_multiplier: float = 1.0

@export var upgrades: Array[SkillUpgradeData]

# Skill sound settings
@export_group("Sound Settings")
@export var cast_sound: AudioStream # Put file here
@export var sound_volume_db: float = 1.0
@export var sound_pitch_scale: float = 1.0
@export var random_pitch: bool = true # Whether to randomize pitch (reduces monotony)
#endregion

# Error/failure sound
@export var error_sound: AudioStream 
@export var error_volume_db: float = 0.0 
@export var error_pitch_scale: float = 1.0
@export var error_random_pitch: bool = false 
#endregion

var cooldown_timer: Timer
var is_active: bool = false

# Current level of this skill node (received from SkillInstance)
var current_level: int = 0:
	set(value):
		current_level = value
		# Force stat application function as soon as the variable value changes!
		apply_upgrades(current_level)

# Original data in inventory that this skill references (SkillInstance)
var skill_instance_ref: SkillInstance = null

# Audio player manager
var _audio_manager: AudioManager

# Sound setup function 
func _setup_sound():
	if (cast_sound or error_sound) and _audio_manager == null:
		_audio_manager = AudioManager.new()
		add_child(_audio_manager)

	# Register cast sound
	if cast_sound:
		var sound_config = AudioManagerPlus.new()
		sound_config.stream = cast_sound
		sound_config.volume_db = sound_volume_db
		sound_config.pitch_scale = sound_pitch_scale
		sound_config.audio_name = "skill_cast"
		
		if "bus" in sound_config:
			sound_config.bus = "SFX"
		else:
			sound_config.set("bus", "SFX") 
			
		_audio_manager.add_plus("skill_cast", sound_config)

	# Register error sound
	if error_sound:
		var error_config = AudioManagerPlus.new()
		error_config.stream = error_sound
		error_config.volume_db = error_volume_db
		error_config.pitch_scale = error_pitch_scale
		error_config.audio_name = "skill_error" 
		_audio_manager.add_plus("skill_error", error_config)
		
# Playback function
func _play_sound():
	if _audio_manager:
		# Random pitch logic 
		if random_pitch: # Reduce monotony
			var config = _audio_manager.get_plus("skill_cast")
			if config:
				# Slightly modify from original pitch
				config.pitch_scale = sound_pitch_scale + randf_range(-0.2, 0.2)
		
		# Play command
		_audio_manager.play_plus("skill_cast")
		
# Play error sound
func play_error_sound():
	if _audio_manager and error_sound:
		if error_random_pitch:
			var config = _audio_manager.get_plus("skill_error")
			if config:
				config.pitch_scale = error_pitch_scale + randf_range(-0.1, 0.1)
		_audio_manager.play_plus("skill_error")

func _ready():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	add_child(cooldown_timer)
	
	_setup_sound()

# Skill availability
func is_ready() -> bool:
	if cooldown_timer == null:
		return false
	return cooldown_timer.is_stopped()

#region Skill Casting
func execute(owner: CharacterBody2D, target: Node2D = null):
	is_active = true
	print(owner.name + " casts " + skill_name + "!")
	# Play sound
	_play_sound()
	

func start_cooldown():
	if cooldown_timer != null:
		cooldown_timer.wait_time = cooldown
		cooldown_timer.start()
		
func process_skill_physics(owner: CharacterBody2D, delta: float):
	pass

func get_cooldown_time_left() -> float:
	if cooldown_timer != null:
		return cooldown_timer.time_left
	return 0.0
#endregion

# Skill upgrade
func apply_upgrades(level: int):
	
	var index = level - 1
	
	if index < 0:
		return
		
	for data in upgrades:
		if data.stat_name in self:
			if index < data.stat_values_by_level.size():
				# Overwrite value
				self.set(data.stat_name, data.stat_values_by_level[index])
				print("Skill upgrade applied: ", data.stat_name, " -> ", data.stat_values_by_level[index])
			else:
				print("Upgrade data missing for Level ", level, " (Index ", index, ")")
