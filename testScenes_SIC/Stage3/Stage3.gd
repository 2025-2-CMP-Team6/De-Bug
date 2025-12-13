extends World

func _ready():
	super() # Call World class's _ready() (connect enemy signals, play music, etc.)

	skill_ui_unlocked = true
	# Unlock player input after camera intro effect
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage3 start: Player input unlocked")

func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Execute World's portal check first (verify all enemies are defeated)
	if not portal_enabled:
		print(">>> Portal cannot be used yet! Defeat all enemies. <<<")
		return

	print("Player entered portal!")
	SceneTransition.fade_to_scene("res://testScenes_SIC/Stage4/Stage4.tscn")


func _on_booby_trap_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
