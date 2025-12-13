extends World


# Called when the node enters the scene tree for the first time.
func _ready():
	super() # Call World class's _ready() (connect enemy signals, play music, etc.)
	skill_ui_unlocked = true
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage4 start: Player input unlocked")

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Execute World's portal check first (verify all enemies are defeated)
	if not portal_enabled:
		print(">>> Portal cannot be used yet! Defeat all enemies. <<<")
		return

	print("Player entered portal!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/StageBoss/StageBoss.tscn")
