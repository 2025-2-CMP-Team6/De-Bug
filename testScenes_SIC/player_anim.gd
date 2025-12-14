# owner : Shin I Cheol
extends AnimatedSprite2D

var player: CharacterBody2D = null

func _ready():
	player = get_parent().get_parent() if get_parent() else null

func _process(_delta):
	match GameManager.state:
		GameManager.State.IDLE: play("idle")
		GameManager.State.MOVE: play("run")
		GameManager.State.DASH: play("DASH") # Temporary Dash animation for now
		GameManager.State.SKILL_CASTING: play("attack", 3) # Should be adjusted based on skill casting time?
	if player and not player.is_on_floor():
		play("jump")
