# owner : Shin I Cheol
extends Camera2D

func _ready():
	# Wait for the scene tree to be ready and then start setup.
	# (This gives other nodes time to load and get into position)
	await get_tree().process_frame 
	
	find_and_set_limits()

func find_and_set_limits():
	var background_node = get_tree().get_first_node_in_group("CameraMapLimit")

	if background_node == null:
		print("Warning: Cannot find background node with 'MapLimit' group.")
		return

	if not background_node is Sprite2D:
		print("Warning: Found node is not a Sprite2D.")
		return

	# If background node is found, call the limit setting function.
	set_limits_from_sprite(background_node)

func set_limits_from_sprite(sprite: Sprite2D):
	# Calculate the global rectangular range of the sprite
	var rect = sprite.get_rect()
	var global_rect = sprite.get_global_transform() * rect

	# Set camera limits
	limit_left = int(global_rect.position.x)
	limit_top = int(global_rect.position.y)
	limit_right = int(global_rect.end.x)
	limit_bottom = int(global_rect.end.y)

	print("Camera range setup complete: ", global_rect)
