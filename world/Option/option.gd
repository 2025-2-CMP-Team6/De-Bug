extends Control

@onready var master_slider = $Panel/VBoxContainer/MasterVolumeSlider
@onready var music_slider = $Panel/VBoxContainer/MusicVolumeSlider
@onready var sfx_slider = $Panel/VBoxContainer/SFXVolumeSlider

@onready var master_value_label = $Panel/VBoxContainer/MasterVolumeValue
@onready var music_value_label = $Panel/VBoxContainer/MusicVolumeValue
@onready var sfx_value_label = $Panel/VBoxContainer/SFXVolumeValue


func _ready():
	# Load saved volume settings if they exist
	_load_audio_settings()

	# Update the display values
	_update_volume_labels()


func _on_master_volume_changed(value: float):
	# Set the master audio bus volume
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

	# Update the display
	master_value_label.text = str(int(value)) + "%"

	# Save the setting
	_save_audio_settings()


func _on_music_volume_changed(value: float):
	# Set the music audio bus volume (if you have a separate bus)
	# For now, we'll just save the value
	music_value_label.text = str(int(value)) + "%"

	# Save the setting
	_save_audio_settings()


func _on_sfx_volume_changed(value: float):
	# Set the SFX audio bus volume (if you have a separate bus)
	# For now, we'll just save the value
	sfx_value_label.text = str(int(value)) + "%"

	# Save the setting
	_save_audio_settings()


func _on_back_button_pressed():
	# Go back to the start screen
	get_tree().change_scene_to_file("res://world/StartScreen/start_screen.tscn")


func _update_volume_labels():
	master_value_label.text = str(int(master_slider.value)) + "%"
	music_value_label.text = str(int(music_slider.value)) + "%"
	sfx_value_label.text = str(int(sfx_slider.value)) + "%"


func _save_audio_settings():
	# Save audio settings to a config file
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save("user://audio_settings.cfg")


func _load_audio_settings():
	# Load audio settings from config file
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")

	if err == OK:
		master_slider.value = config.get_value("audio", "master_volume", 100.0)
		music_slider.value = config.get_value("audio", "music_volume", 80.0)
		sfx_slider.value = config.get_value("audio", "sfx_volume", 80.0)

		# Apply the master volume
		var volume_db = linear_to_db(master_slider.value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
