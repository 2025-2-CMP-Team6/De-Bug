# owner : Shin I Cheol
extends World

@export var ending_transition_sound: AudioStream

func _ready() -> void:
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		
func _on_portal_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Portal is always enabled in ending scene
	print("Ending: Player entered portal. Transitioning to credits with white fade...")

	# Play transition sound effect
	if ending_transition_sound:
		if _audio_manager == null:
			_audio_manager = AudioManager.new()
			add_child(_audio_manager)

		var sfx_plus = AudioManagerPlus.new()
		sfx_plus.stream = ending_transition_sound
		sfx_plus.volume_db = 0.0
		sfx_plus.loop = false
		sfx_plus.audio_name = "EndingTransition"

		# Register and play the sound
		_audio_manager.add_plus("EndingTransition", sfx_plus)
		_audio_manager.play_plus("EndingTransition")

	SceneTransition.white_fade_to_scene("res://testScenes_SIC/StageEnding/EndingCredit.tscn", 3.0)
