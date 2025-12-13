extends World

# Load Dialogue resource
var dialogue_resource = preload("res://testScenes_SIC/dialogue/stage1.dialogue")

# Respawn related variables
var spawn_position: Vector2 = Vector2(310.99988, 5081.0005) # Player start position
var current_respawn_position: Vector2 # Current respawn position (position of most recently killed enemy)
var highest_checkpoint_number: int = 0 # Number of enemy set as current checkpoint (only keep highest number)

# Tutorial related variables
var is_first_skill_selection: bool = false # Track if this is the first skill selection after defeating tutorial boss

func _ready():
	super() # Required for audio manager setup. Put desired music in Stage Settings in inspector.

	# Initialize respawn position
	current_respawn_position = spawn_position

	# Connect tutorial enemy checkpoints
	_connect_enemy_checkpoints()

	# Connect tutorial trigger signals (if they exist in scene)
	_connect_tutorial_triggers()

	# Unlock skill window when tutorial boss is defeated
	_connect_tutorial_boss()

	# Connect signal to display dialogue after skill selection
	if is_instance_valid(skill_get_ui):
		skill_get_ui.closed.connect(_on_first_skill_selected)

	# Execute camera intro effect (use common function from world.gd)
	await camera_intro_effect()

	# Find player
	var stage_player = player if player != null else get_node_or_null("Player")

	# Lock player input before starting intro dialogue
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("=== Intro start: Player input locked ===")

	# Start dialogue after intro effect ends
	var balloon = DialogueManager.show_dialogue_balloon_scene("res://testScenes_SIC/dialogue/stage1_balloon.tscn", dialogue_resource, "start")

	# Connect balloon's dialogue_finished signal
	balloon.dialogue_finished.connect(_on_dialogue_ended)

# Connect tutorial enemy checkpoints
func _connect_enemy_checkpoints():
	# Connect enemy_died signals for virus, virus2, virus3
	var enemies_to_track = ["Virus", "Virus2", "Virus3"]

	for enemy_name in enemies_to_track:
		var enemy = get_node_or_null(enemy_name)
		if enemy and enemy.has_signal("enemy_died"):
			# Set that enemy's position as checkpoint when it dies
			enemy.enemy_died.connect(func(): _on_enemy_checkpoint_reached(enemy, enemy_name))
			print("Checkpoint connected: ", enemy_name)

func _on_enemy_checkpoint_reached(enemy: Node2D, enemy_name: String):
	# Extract number from enemy name ("Virus" -> 1, "Virus2" -> 2, "Virus3" -> 3)
	var enemy_number = _extract_enemy_number(enemy_name)

	print("=== Enemy defeated: ", enemy_name, " (number: ", enemy_number, ") ===")
	print("Current highest checkpoint number: ", highest_checkpoint_number)

	# Update checkpoint only when a higher numbered enemy is killed
	if enemy_number > highest_checkpoint_number:
		highest_checkpoint_number = enemy_number
		current_respawn_position = enemy.global_position
		print(">>> Checkpoint updated! New respawn position: ", current_respawn_position)
	else:
		print(">>> Checkpoint maintained (current checkpoint has higher number)")

# Function to extract number from enemy name
func _extract_enemy_number(enemy_name: String) -> int:
	# "Virus" -> 1, "Virus2" -> 2, "Virus3" -> 3
	if enemy_name == "Virus":
		return 1
	elif enemy_name.begins_with("Virus"):
		# Extract only number part from "Virus2", "Virus3", etc.
		var number_part = enemy_name.substr(5)  # Characters after "Virus"
		if number_part.is_valid_int():
			return int(number_part)
	return 0  # Return 0 for unknown cases

# Unlock skill window when tutorial boss is defeated
func _connect_tutorial_boss():
	var tutorial_boss = get_node_or_null("TutorialBoss")
	if tutorial_boss and tutorial_boss.has_signal("enemy_died"):
		tutorial_boss.enemy_died.connect(_on_tutorial_boss_defeated)
		print("Tutorial boss signal connected")

func _on_tutorial_boss_defeated():
	print("=== Tutorial boss defeated! ===")

	# Set first skill selection flag
	is_first_skill_selection = true

	# Find player
	var stage_player = player if player != null else get_node_or_null("Player")

	# Lock player input (during dialogue display)
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("Player input locked (dialogue after boss defeat)")

	# Start dialogue after boss defeat
	var balloon = DialogueManager.show_dialogue_balloon_scene(
		"res://testScenes_SIC/dialogue/stage1_balloon.tscn",
		dialogue_resource,
		"tutorial_boss_defeated"
	)

	# Unlock player input when dialogue ends (skill selection window opens)
	balloon.dialogue_finished.connect(func():
		if stage_player and stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("Player input unlocked - skill selection available")
	)

# Function called after first skill selection
func _on_first_skill_selected():
	# Ignore if not first skill selection
	if not is_first_skill_selection:
		return

	is_first_skill_selection = false
	print("=== First skill selection complete! ===")

	# Find player
	var stage_player = player if player != null else get_node_or_null("Player")

	# Lock player input (during dialogue display)
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("Player input locked (skill explanation dialogue)")

	# Start dialogue explaining how to use skills
	var balloon = DialogueManager.show_dialogue_balloon_scene(
		"res://testScenes_SIC/dialogue/stage1_balloon.tscn",
		dialogue_resource,
		"after_skill_selection"
	)

	# Unlock skill UI and unlock player input when dialogue ends
	balloon.dialogue_finished.connect(func():
		unlock_skill_ui()
		if stage_player and stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("Player input unlocked - game continues")
	)

# Automatically connect tutorial trigger signals
func _connect_tutorial_triggers():
	# Connect TutorialTrigger_Dash
	var dash_trigger = get_node_or_null("DashTutorial")
	if dash_trigger:
		dash_trigger.body_entered.connect(func(body): _on_tutorial_trigger_entered(body, "dash", "tutorial_dash"))
		print("Dash tutorial trigger connected")

	# Add additional tutorial triggers here if any
	var skill_trigger = get_node_or_null("SkillTutorial")
	if skill_trigger:
		skill_trigger.body_entered.connect(func(body): _on_tutorial_trigger_entered(body, "skill", "tutorial_skill"))

	var middleBoss_trigger = get_node_or_null("MiddleBossTutorial")
	if middleBoss_trigger:
		middleBoss_trigger.body_entered.connect(func(body): _on_tutorial_trigger_entered(body, "middleBoss", "tutorial_middleBoss"))

func _on_fall_prevention_body_entered(body: Node2D):
	if body.is_in_group("player"):
		respawn_player(body)

func respawn_player(player: Node2D):
	if player:
		# Move player to current checkpoint position
		player.global_position = current_respawn_position
		# Reset velocity
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		print("Player respawned! Position: ", current_respawn_position)

# Track first dialogue completion
var first_dialogue_done: bool = false

# Track tutorial triggers (run only once)
var tutorial_triggers_activated: Dictionary = {}

# Function called when dialogue ends
func _on_dialogue_ended():
	if not first_dialogue_done:
		# Execute camera zoom only when first dialogue ends
		print("=== First dialogue ended, starting portal zoom ===")
		first_dialogue_done = true

		# Execute camera zoom effect to portal (keep input locked)
		await camera_zoom_to_portal(2.0, 1.5, Vector2(1.5, 1.5), Vector2(-400, 200))

		# Start second dialogue after camera zoom ends
		print("=== Portal zoom complete, starting second dialogue ===")
		var balloon = DialogueManager.show_dialogue_balloon_scene("res://testScenes_SIC/dialogue/stage1_balloon.tscn", dialogue_resource, "after_portal")
		balloon.dialogue_finished.connect(_on_dialogue_ended)
	else:
		# When second dialogue ends - now unlock player input
		print("=== All intro dialogues complete, unlocking player input ===")

		var stage_player = player if player != null else get_node_or_null("Player")
		if stage_player and stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("Player can now move!")

# Effect to zoom camera to portal then back to player
func camera_zoom_to_portal(
	portal_show_duration: float = 2.0,  # Time to show portal
	zoom_duration: float = 1.5,         # Zoom movement time
	portal_zoom_level: Vector2 = Vector2(1.5, 1.5),  # Portal zoom level
	offset_adjustment: Vector2 = Vector2.ZERO  # Fine position adjustment (e.g.: Vector2(50, -30))
):
	# Find player and camera
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player == null:
		print("Warning: Cannot find Player node.")
		return

	var camera = stage_player.get_node_or_null("Camera2D")
	if camera == null:
		print("Warning: Cannot find Player's Camera2D.")
		return

	# Find portal node (portal node in Stage1.tscn)
	var portal = get_node_or_null("portal")
	if portal == null:
		print("Warning: Cannot find Portal node.")
		print("Available child nodes:")
		for child in get_children():
			print("  - ", child.name)
		return

	print("Portal node found:", portal.name, " position:", portal.global_position)

	# Save current camera settings
	var original_offset = camera.offset
	var original_zoom = camera.zoom
	var original_smoothing = camera.position_smoothing_enabled

	# Disable camera smoothing (to respond immediately)
	camera.position_smoothing_enabled = false

	# Calculate portal center position
	# Portal is Area2D so get exact center
	var portal_center = portal.global_position

	# Calculate offset to portal from player's perspective
	var portal_offset = portal_center - stage_player.global_position + offset_adjustment

	print("Player position:", stage_player.global_position)
	print("Portal center:", portal_center)
	print("Calculated offset:", portal_offset)
	print("Adjustment value:", offset_adjustment)

	# Move camera to portal position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)  # Execute simultaneously

	tween.tween_property(camera, "offset", portal_offset, zoom_duration)
	tween.tween_property(camera, "zoom", portal_zoom_level, zoom_duration)

	await tween.finished

	# Show portal briefly
	await get_tree().create_timer(portal_show_duration).timeout

	# Return camera back to player
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.set_parallel(true)

	return_tween.tween_property(camera, "offset", original_offset, zoom_duration)
	return_tween.tween_property(camera, "zoom", original_zoom, zoom_duration)

	await return_tween.finished

	# Restore camera smoothing to original
	camera.position_smoothing_enabled = original_smoothing

# Handle tutorial trigger (connected to Area2D's body_entered signal)
func _on_tutorial_trigger_entered(body: Node2D, trigger_name: String, dialogue_title: String):
	# Ignore if not player
	if not body.is_in_group("player"):
		return

	# Ignore if trigger is already activated (run only once)
	if tutorial_triggers_activated.get(trigger_name, false):
		return

	print("=== Tutorial trigger activated: ", trigger_name, " ===")
	tutorial_triggers_activated[trigger_name] = true

	# Find player
	var stage_player = player if player != null else body

	# Lock player input (prevent movement)
	if stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(true)
		print("Player input locked")

	# Disable all enemy AI for skill tutorial
	var paused_enemies = []
	if trigger_name == "skill":
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy and is_instance_valid(enemy):
				enemy.set_process(false)
				enemy.set_physics_process(false)
				paused_enemies.append(enemy)
		print("Enemy AI disabled: ", paused_enemies.size(), " enemies")

	# Start tutorial dialogue
	var balloon = DialogueManager.show_dialogue_balloon_scene(
		"res://testScenes_SIC/dialogue/stage1_balloon.tscn",
		dialogue_resource,
		dialogue_title
	)

	# Unlock player input and restore enemy AI when dialogue ends
	balloon.dialogue_finished.connect(func():
		if stage_player.has_method("set_input_locked"):
			stage_player.set_input_locked(false)
			print("Player input unlocked")

		# Re-enable enemy AI if it was skill tutorial
		if trigger_name == "skill":
			for enemy in paused_enemies:
				if enemy and is_instance_valid(enemy):
					enemy.set_process(true)
					enemy.set_physics_process(true)
			print("Enemy AI enabled: ", paused_enemies.size(), " enemies")
	)

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Execute World's portal check first (verify all enemies are defeated)
	if not portal_enabled:
		print(">>> Portal cannot be used yet! Defeat all enemies. <<<")
		return

	print("Player entered portal!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage2/Stage2.tscn")
