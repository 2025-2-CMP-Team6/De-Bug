extends World


# Called when the node enters the scene tree for the first time.
func _ready():
	var stage_player = player if player != null else get_node_or_null("Player")
	if stage_player and stage_player.has_method("set_input_locked"):
		stage_player.set_input_locked(false)
		print("Stage4 시작: 플레이어 입력 잠금 해제")
