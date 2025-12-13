# Skill_Melee.gd
extends BaseSkill

#region Node References
@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/CollisionShape2D
#endregion

#region Initialization
func _init():
	# ★ You must use this variable instead of 'ignore_gravity'.
	gravity_multiplier = 0.2

func _ready():
	super._ready()
	if hitbox_shape:
		hitbox_shape.disabled = true
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
#endregion

#region Skill Logic
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target)
	if hitbox_shape:
		hitbox_shape.disabled = false
	get_tree().create_timer(cast_duration).timeout.connect(_on_attack_finished)

func _on_attack_finished():
	if hitbox_shape:
		hitbox_shape.disabled = true

func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity.x = 0

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemies"):
		EffectManager.play_screen_shake(8.0, 0.1)
		EffectManager.play_screen_flash(Color.WHITE, 0.05)

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemies"):
		EffectManager.play_screen_shake(8.0, 0.1)
		EffectManager.play_screen_flash(Color.WHITE, 0.05)
#endregion
