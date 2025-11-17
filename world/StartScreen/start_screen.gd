extends Control


func _ready():
	pass


func _on_start_button_pressed():
	# Load and change to the world scene
	get_tree().change_scene_to_file("res://world/world.tscn")


func _on_options_button_pressed():
	# Load and change to the options scene
	get_tree().change_scene_to_file("res://world/Option/option.tscn")


func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()
