extends World

var spawn_position: Vector2 = Vector2(10095.0, 4196.0) # Player start position
var current_respawn_position: Vector2 # Current respawn position (position of most recently killed enemy)

# Checkpoint group definition
# Each group: { enemies: [enemy names], respawn_provider: enemy name that provides respawn position }
var checkpoint_groups = {
	"group1": {
		"enemies": ["Virus", "Virus2"],
		"respawn_provider": "Virus"
	},
	"group2": {
		"enemies": ["RangeVirus", "RangeVirus2", "RangeVirus3"],
		"respawn_provider": "RangeVirus3"
	},
	"group3": {
		"enemies": ["Virus3", "Virus4", "RangeVirus3"],
		"respawn_provider": "Virus3"
	}
}

# Track enemy death status
var dead_enemies: Dictionary = {}

# Track checkpoint completion (prevent duplicate messages)
var completed_checkpoints: Dictionary = {}

func _ready():
	super() # Call World class's _ready() (connect enemy signals, play music, etc.)

	current_respawn_position = spawn_position

	# Automatically unlock skill UI from Stage2 onwards (after tutorial)
	skill_ui_unlocked = true

	# Connect checkpoint group enemy signals
	_connect_checkpoint_enemies()

	await camera_intro_effect(Vector2(0.23, 0.27))

	# Unlock player input after camera intro effect
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage2 start: Player input unlocked")

# Connect checkpoint group enemy signals
func _connect_checkpoint_enemies():
	# Collect all enemies from all groups (remove duplicates)
	var all_enemies_set = {}
	for group_name in checkpoint_groups:
		var group = checkpoint_groups[group_name]
		for enemy_name in group.enemies:
			all_enemies_set[enemy_name] = true

	# Connect each enemy's enemy_died signal
	for enemy_name in all_enemies_set:
		var enemy = get_node_or_null(enemy_name)
		if enemy and enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(func(): _on_checkpoint_enemy_died(enemy, enemy_name))
			print("Checkpoint enemy connected: ", enemy_name)
			# Initial death status is false
			dead_enemies[enemy_name] = false

# Called when checkpoint enemy dies
func _on_checkpoint_enemy_died(enemy: Node2D, enemy_name: String):
	print("=== Enemy defeated: ", enemy_name, " ===")

	# Process death
	dead_enemies[enemy_name] = true

	# Check all groups this enemy belongs to
	for group_name in checkpoint_groups:
		var group = checkpoint_groups[group_name]

		# Skip if this group's checkpoint is already achieved
		if completed_checkpoints.get(group_name, false):
			continue

		# Check if this enemy belongs to this group
		if enemy_name in group.enemies:
			# Check if all enemies in group are dead
			var all_dead = true
			for group_enemy_name in group.enemies:
				if not dead_enemies.get(group_enemy_name, false):
					all_dead = false
					break

			# If all dead, update respawn position
			if all_dead:
				var respawn_provider_name = group.respawn_provider
				var respawn_provider = get_node_or_null(respawn_provider_name)

				if respawn_provider:
					current_respawn_position = respawn_provider.global_position
					completed_checkpoints[group_name] = true
					print(">>> Checkpoint achieved! (", group_name, ") New respawn position: ", respawn_provider_name, " - ", current_respawn_position)
				else:
					print("Warning: Cannot find respawn provider: ", respawn_provider_name)

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Execute World's portal check first (verify all enemies are defeated)
	if not portal_enabled:
		print(">>> Portal cannot be used yet! Defeat all enemies. <<<")
		return

	print("Player entered portal!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage3/Stage3.tscn")

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
