extends Node2D

@onready var video_player = $VideoStreamPlayer

func _ready():
	if video_player:
		# Connect to the finished signal to detect when video ends
		video_player.finished.connect(_on_video_finished)

		# Start playing the video
		video_player.play()
		print("Ending credit video started")
	else:
		push_error("VideoStreamPlayer not found in EndingCredit scene!")

func _on_video_finished():
	print("Ending credit video finished. Returning to start screen...")
	# Return to start screen with fade transition
	SceneTransition.fade_to_scene("res://world/StartScreen/start_screen.tscn", 1.0)
