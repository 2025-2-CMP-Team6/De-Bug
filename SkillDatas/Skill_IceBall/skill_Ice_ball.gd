#skill_Ice_ball.gd
#owner: Choi eunyoung

extends BaseSkill

#region 1. Node References & Settings
# Instead of the template hitbox, we grab the original bullet that we'll duplicate and use.
@onready var bullet_template = $BulletTemplate

func _init():
	# [Design settings]
	# Whether targeting is required (false: non-target skill, fires in the facing direction)
	requires_target = false
	
	# Gravity multiplier (1.0: stays grounded, doesn't float during casting)
	gravity_multiplier = 1.0
	
	# Conditional ending (false: skill state ends after cast time)
	ends_on_condition = false

func _ready():
	super._ready() # ★ Required: initialize the cooldown timer
	
	# Hide/disable the original bullet template at game start.
	if bullet_template:
		bullet_template.visible = false
		bullet_template.monitoring = false
#endregion

#region 2. Skill Execution (Execute)
# Runs exactly once when the player presses the skill key.
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target) # ★ Required: change state values
	
	print(skill_name + " activated! Iceball")
	
	# [Execution logic]
	# 1. Duplicate the bullet (use Duplicate instead of Instantiate)
	var bullet = bullet_template.duplicate()
	
	# 2. Configure the duplicated bullet
	bullet.visible = true
	bullet.monitoring = true
	bullet.top_level = true # ★ Important: don't follow the player; use world coordinates
	bullet.global_position = owner.global_position # Position: player's position
	
	# 3. Set direction
	var direction = Vector2.RIGHT
	var angle_right = -138.2
	var angle_left = 138.2

	# Check if owner.visuals.scale.x is negative (facing left)
	if owner.visuals.scale.x < 0: 
		direction = Vector2.LEFT 
		
		# When facing left: flip scale, and use a positive (+) angle
		bullet.scale.x = -abs(bullet.scale.x)
		bullet.rotation_degrees = angle_left 
	else:
		# When facing right: normal scale, and use a negative (-) angle
		bullet.scale.x = abs(bullet.scale.x)
		bullet.rotation_degrees = angle_right

	
	# 4. Add to the scene tree (Fire!)
	get_tree().current_scene.add_child(bullet)
	
	# 5. Make it travel (use Tween)
	var tween = create_tween()
	var distance = 1000.0 # Range
	var travel_time = 1.0 # Projectile speed (smaller = faster)
	
	# Move by direction*distance from the current position
	tween.tween_property(bullet, "global_position", bullet.global_position + (direction * distance), travel_time)
	tween.tween_callback(bullet.queue_free) # Delete after it finishes traveling
	
	# 6. Connect collision (connect directly to the duplicated bullet)
	bullet.body_entered.connect(func(body):
		if body.is_in_group("enemies"):
			# 1. Deal damage
			if body.has_method("take_damage"):
				body.take_damage(damage)
	
			body.modulate = Color(0.5, 1, 1) 
			print("Enemy frozen! (blue color)")

			# 2. Add slow effect
			if body.has_method("apply_slow"):
				body.apply_slow(0.5, 2.0) # 50% slower for 2 seconds
			
			
			print("Enemy frozen!")
			bullet.queue_free() # Delete on hit
			
		# [4] Restore after 3 seconds
			var duration = 2.0
			var timer = get_tree().create_timer(duration)
			
			timer.timeout.connect(func():
				# Check if the enemy is still alive after 3 seconds (avoids errors if dead)
				if is_instance_valid(body):
					# A. Restore color (this was missing, so it didn't revert!)
					body.modulate = Color.WHITE 
					print("Enemy thawed! (original speed restored)")
					)
					
		elif body != owner:
				bullet.queue_free() # Delete when hitting a wall
	)

	# 7. Set end timer (player stiffness / recovery time)
	if not ends_on_condition:
		get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

# Function called when the skill ends
func _on_skill_finished():
	pass
#endregion

#region 3. Physics Processing (Physics)
# Runs every frame during skill casting.
func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity.x = 0
#endregion

#region 4. Collision Handling (Collision)
func _on_hitbox_area_entered(area):
	pass
#endregion
