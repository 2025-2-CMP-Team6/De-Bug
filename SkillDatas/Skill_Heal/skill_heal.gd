#skill_heal.gd
#owner: Choi eunyoung


extends BaseSkill

#region Skill-Specific Settings
@onready var particles = $HealParticles 
#endregion

# Internal flag to block cooldown activation
var _cancel_activation: bool = false

func _init():
	skill_name = "Heal"
	type = 3 
	requires_target = false 
	cast_duration = 0.5
	gravity_multiplier = 1.0 

func _ready():
	super._ready()
	if particles:
		particles.emitting = false
		particles.one_shot = true

func execute(owner: CharacterBody2D, target: Node2D = null):
	# [Step 1] Check if HP is full
	if _is_hp_full(owner):
		print("Cannot use the skill because HP is full.")
		play_error_sound()
		_cancel_activation = true
		
		# Refund stamina
		if "current_stamina" in owner:
			owner.current_stamina += stamina_cost
			# Clamp so it doesn't exceed the maximum
			if "max_stamina" in owner:
				owner.current_stamina = min(owner.current_stamina, owner.max_stamina)
		
		# Immediately cancel casting motion (force switch to IDLE)
		if owner.has_method("change_state"):
			owner.change_state(GameManager.State.IDLE)
			
		return

	# Normal activation
	super.execute(owner, target)
	_cancel_activation = false 
	
	print("Heal skill activated!")

	# Sync player state
	if owner.has_method("change_state"):
		owner.change_state(GameManager.State.SKILL_CASTING)

	# HP recovery logic
	if "current_lives" in owner:
		owner.current_lives += 1
		owner.update_lives_ui()
		print(" - Life recovered! Current: ", owner.current_lives)
		
	# Play effects
	if particles:
		particles.restart()
		particles.emitting = true
	
	# Schedule end
	get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

func start_cooldown():
	# If activation was canceled, do not start the cooldown timer.
	if _cancel_activation:
		_cancel_activation = false # Reset
		return 

	super.start_cooldown()

func _is_hp_full(owner) -> bool:
	# If using the hearts (Lives) system
	if "current_lives" in owner and "max_lives" in owner:
		return owner.current_lives >= owner.max_lives
		
	# If using the HP bar system
	if "health" in owner and "max_health" in owner:
		return owner.health >= owner.max_health
		
	return false # If variables don't exist, allow activation by default

func _on_skill_finished():
	is_active = false
	if particles:
		particles.emitting = false
