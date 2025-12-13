# skills/blink_slash/Skill_BlinkSlash.gd
extends BaseSkill

#region Skill-Specific Properties
@export var teleport_distance: float = 60.0
@export var safety_margin: float = 50.0
@export var hitbox_width: float = 50.0
@export var slash_visual_texture: Texture
#endregion

var slide_direction: Vector2 = Vector2.ZERO

# -----------------------------------------------------------------
# (Newly added) _init function
# -----------------------------------------------------------------
func _init():
	# 1. This skill requires a target.
	requires_target = true
	
	# 2. This skill ends by time. (Sliding removed)
	ends_on_condition = false
	
	# 3. (Bug fix) Set gravity multiplier to 1.0 (100%).
	gravity_multiplier = 1.0
# -----------------------------------------------------------------

#region Skill Logic
func execute(owner: CharacterBody2D, target: Node2D = null):
	super.execute(owner, target)
	
	if target == null:
		is_active = false
		return
	if not target.has_method("get_rid"):
		is_active = false
		return
	
	var start_pos = owner.global_position
	slide_direction = (target.global_position - start_pos).normalized()
	if slide_direction == Vector2.ZERO:
		slide_direction = Vector2.RIGHT
	
	var ray_from = target.global_position
	var ray_to = ray_from + (slide_direction * teleport_distance)
	var space_state = owner.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(ray_from, ray_to)
	query.exclude = [owner.get_rid(), target.get_rid()]
	var result = space_state.intersect_ray(query)
	
	var target_position: Vector2
	if result:
		target_position = result.position - (slide_direction * safety_margin)
	else:
		target_position = ray_to

	owner.global_position = target_position

	# Reset Physics Interpolation (so physics queries use the correct position after teleport)
	if owner.has_method("reset_physics_interpolation"):
		owner.reset_physics_interpolation()

	apply_slash_damage(start_pos, target_position, owner)

func apply_slash_damage(start_pos: Vector2, end_pos: Vector2, owner: CharacterBody2D):
	var length = start_pos.distance_to(end_pos)
	var space_state = owner.get_world_2d().direct_space_state
	var shape = RectangleShape2D.new()
	shape.size = Vector2(hitbox_width, length)
	
	var angle = (end_pos - start_pos).angle() + deg_to_rad(90)
	var center_pos = (start_pos + end_pos) / 2
	var xform = Transform2D(angle, center_pos)

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xform

	# Fix 1: Changed to detect Area2D (hitboxes) as well
	query.collide_with_areas = true
	query.collide_with_bodies = true

	# Fix: Set collision_mask (Layer 3 = Enemy)
	query.collision_mask = 0xFFFFFFFF  # Detect all layers

	query.exclude = [owner.get_rid()] # Exclude the player itself
	
	_debug_draw_hitbox(shape, xform, owner)

	var results = space_state.intersect_shape(query)

	print("=== BlinkSlash Debug ===")
	print("Detected object count: ", results.size())

	var did_hit_enemy = false
	var hit_enemies = [] # List to prevent duplicate hits

	for res in results:
		print("  - Detected object: ", res.collider.name, " (Type: ", res.collider.get_class(), ")")
		var collider = res.collider
		var enemy_node = null
		
		# Fix 2: Check whether the collision was with the enemy body or the enemy hitbox
		print("    - Belongs to 'enemies' group? ", collider.is_in_group("enemies"))
		if collider.is_in_group("enemies"):
			# Collided with enemy body
			enemy_node = collider
			print("    -> Recognized as enemy body")

		elif collider is Area2D and collider.get_parent().is_in_group("enemies"):
			# Collided with enemy hitbox (Area) -> treat parent as the enemy body
			enemy_node = collider.get_parent()
			print("    -> Recognized as enemy hitbox, parent: ", enemy_node.name)

		# ★ Fix 3: If an enemy was found and hasn't been hit yet, apply damage
		if enemy_node != null and not enemy_node in hit_enemies:
			print("    -> Enemy found! Has take_damage method? ", enemy_node.has_method("take_damage"))
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(damage)
				print("    ✓ BlinkSlash hit: " + enemy_node.name + " (Damage: " + str(damage) + ")")
				hit_enemies.append(enemy_node) # Add to hit list
				did_hit_enemy = true
			else:
				print("    ✗ No take_damage method!")

	# Effects
	if did_hit_enemy:
		EffectManager.play_screen_shake(12.0, 0.15)
		EffectManager.play_multi_flash(Color.WHITE, 0.05, 3)
		
# Hitbox visualization
func _debug_draw_hitbox(shape: Shape2D, xform: Transform2D, owner: Node):
	var debug_sprite = Sprite2D.new()
	
	if slash_visual_texture:
		debug_sprite.texture = slash_visual_texture
	else:
		return

	if debug_sprite.texture.get_width() > 0:
		debug_sprite.scale.x = shape.size.x / debug_sprite.texture.get_width()
		debug_sprite.scale.y = shape.size.y / debug_sprite.texture.get_height()

	debug_sprite.modulate = Color(1, 1, 1, 0.5)
	debug_sprite.global_transform = xform
	
	owner.get_parent().add_child(debug_sprite)
	
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(debug_sprite.queue_free)
#endregion
