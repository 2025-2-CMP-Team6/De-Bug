extends Node2D

@onready var player = $Player_test

# Dialogue 리소스 로드
var dialogue_resource = preload("res://testScenes_SIC/dialogue/test.dialogue")

func _ready():
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")
