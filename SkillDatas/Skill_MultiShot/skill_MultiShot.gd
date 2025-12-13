extends BaseSkill

#region 1. Node References & Settings
# Template for duplicating bullets
@onready var bullet_template = $BulletTemplate

func _init():
	# Whether targeting is required (false: non-target skill, fires in the facing direction)
	requires_target = false
	# Gravity multiplier (1.0: stays grounded, doesn't float during casting)
	gravity_multiplier = 1.0
	# Conditional ending (false: skill state ends after cast time)
	ends_on_condition = false

func _ready():
	super._ready() # Initialize the cooldown timer

	if bullet_template:
		bullet_template.visible = false
		bullet_template.monitoring = false
#endregion

#region 2. Skill Execution (Execute)
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target)
	
	print(skill_name + " activated! (Multi-shot)")
	
	# --- [Settings] ---
	var bullet_count = 3       # Number of bullets to fire
	var spread_angle = 15.0    # Angle between bullets (spread amount)
	var distance = 600.0       # Range
	var travel_time = 0.8      # Travel time
	
	# Base rotation for the bullet sprite (image rotation correction)
	var angle_right = -138.2
	var angle_left = 138.2
	# ----------------
	
	# Loop for firing multiple shots
	for i in range(bullet_count):
		# 1. Duplicate bullet
		var bullet = bullet_template.duplicate()
		bullet.visible = true
		bullet.monitoring = true
		bullet.top_level = true 
		bullet.global_position = owner.global_position

		get_tree().current_scene.add_child(bullet)

		# 2. Base setup depending on player direction
		var base_direction = Vector2.RIGHT
		var base_rotation = 0.0
		
		# Check if owner.visuals.scale.x is negative (facing left)
		if owner.visuals.scale.x < 0: 
			base_direction = Vector2.LEFT 
			
			# When facing left: flip scale, and use a positive (+) angle
			bullet.scale.x = -abs(bullet.scale.x)
			base_rotation = angle_left
		else:
			# When facing right: normal scale, and use a negative (-) angle
			bullet.scale.x = abs(bullet.scale.x)
			base_rotation = angle_right

		# 3. Calculate multi-shot angle (create a fan shape)
		# i=0(-15°), i=1(0°), i=2(+15°)
		var center_index = float(bullet_count - 1) / 2.0
		var spread_offset = spread_angle * (i - center_index)

		if base_direction == Vector2.LEFT:
			spread_offset = -spread_offset

		# Apply final angle (base sprite angle + spread offset)
		bullet.rotation_degrees = base_rotation + spread_offset
		
		# 4. Calculate travel direction vector
		var travel_direction = base_direction.rotated(deg_to_rad(spread_offset))
		
		# 5. Fire (Tween)
		var tween = create_tween()
		# Move by (direction * distance) from the current position
		tween.tween_property(bullet, "global_position", bullet.global_position + (travel_direction * distance), travel_time)
		# Delete after it finishes traveling
		tween.tween_callback(bullet.queue_free)

		# 6. Connect collision
		bullet.body_entered.connect(func(body):
			# 1. When hitting an enemy (do not delete; piercing)
			if body.is_in_group("enemies"):
				if body.has_method("take_damage"):
					body.take_damage(damage) 
				
				bullet.modulate.a = 0.8
				print("Multi-shot arrow pierced an enemy!")

			# 2. Walls/floor, etc.
			elif body != owner:
				if body is TileMap or body.is_in_group("walls"):
					bullet.queue_free()
				elif not body.is_in_group("projectiles"): 
					bullet.queue_free()
		)

	# 7. Set end timer
	if not ends_on_condition:
		get_tree().create_timer(cast_duration).timeout.connect(_on_skill_finished)

# Function called when the skill cast time ends
func _on_skill_finished():
	pass
#endregion

#region 3. Physics Processing (Physics)
func process_skill_physics(owner: CharacterBody2D, delta: float):
	owner.velocity.x = 0
#endregion

#region 4. Collision Handling (Collision)
func _on_hitbox_area_entered(area):
	pass
#endregion
