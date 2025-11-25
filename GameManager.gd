# GameManager.gd
extends Node

var is_cheat: bool = false
var is_free_cam: bool = false
var is_dragging: bool = false
#region 상태 머신 (State Machine)
enum State {
	IDLE,
	MOVE,
	DASH,
	SKILL_CASTING
}

var state: int = State.IDLE
#endregion

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	

func _input(event):
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				is_cheat = !is_cheat
				printc("now cheat available." if is_cheat else "now cheat unavailable.")
			KEY_F2:
				_toggle_free_camera()
			
	
	if is_free_cam:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_dragging = event.pressed
		
		elif event is InputEventMouseMotion and is_dragging:
			_move_camera(event.relative)
	
func _toggle_free_camera():
	var player = get_tree().get_first_node_in_group("player")

	if not player:
		return
	if not player.camera_node:
		player.camera_node = player.get_node_or_null("Camera2D")
		if not player.camera_node:
			return
	is_free_cam = not is_free_cam
	get_tree().paused = is_free_cam

	if is_free_cam:
		printc("Free Camera ON")
	else:
		printc("Free Camera OFF")
	player.camera_node.position = Vector2.ZERO
func _move_camera(relative: Vector2):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.camera_node:
		var zoom = player.camera_node.zoom
		player.camera_node.global_position -= relative / zoom

func printc(text: String):
	print("[CHEAT] " + text)