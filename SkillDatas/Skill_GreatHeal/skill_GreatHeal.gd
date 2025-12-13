extends BaseSkill

#region Skill Settings
@export var heal_amount: int = 3     
@export var max_overheal: int = 2      # Maximum bonus HP
@onready var particles = $GreatHealParticles 
#endregion

# Flag to block cooldown/stamina on cancel
var _cancel_activation: bool = false

func _init():
	skill_name = "GreatHeal"
	type = 3 
	requires_target = false 
	cast_duration = 1.0 
	stamina_cost = 50.0 
	gravity_multiplier = 1.0 

func _ready():
	super._ready()
	if particles:
		particles.emitting = false
		particles.one_shot = true

func execute(owner: CharacterBody2D, target: Node2D = null):
	var absolute_max_lives = 7 # Default value
	if "max_lives" in owner:
		absolute_max_lives = owner.max_lives + max_overheal
	
	# Check if it's already filled up to the limit
	if "current_lives" in owner and owner.current_lives >= absolute_max_lives:
		print("Overheal limit reached! Cannot heal any further.")
		
		play_error_sound() 
		_cancel_activation = true # Prevent cooldown
		
		# Refund stamina
		if "current_stamina" in owner:
			owner.current_stamina += stamina_cost
			if "max_stamina" in owner:
				owner.current_stamina = min(owner.current_stamina, owner.max_stamina)
		
		# Cancel motion
		if owner.has_method("change_state"):
			owner.change_state(GameManager.State.IDLE)
		return

	# Normal activation
	super.execute(owner, target)
	_cancel_activation = false
	
	print("GreatHeal activated!")

	if owner.has_method("change_state"):
		owner.change_state(GameManager.State.SKILL_CASTING)

	if "current_lives" in owner:
		# Expected heal amount: current + 3
		var potential_lives = owner.current_lives + heal_amount
		
		# Choose the smaller value (potential vs limit)
		owner.current_lives = min(potential_lives, absolute_max_lives)
		
		owner.update_lives_ui() # Draw yellow hearts (Player.gd logic)
		print(" - Life recovered! Current: ", owner.current_lives, " / Absolute limit: ", absolute_max_lives)

	if particles:
		particles.restart()
		particles.emitting = true
	
	get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

# Cooldown control
func start_cooldown():
	if _cancel_activation:
		_cancel_activation = false
		return 
	super.start_cooldown()

func _on_skill_finished():
	is_active = false
	if particles:
		particles.emitting = false
