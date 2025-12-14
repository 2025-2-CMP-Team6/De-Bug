# BoobyTrap.gd
# owner : Shin I Cheol
extends Area2D

@export var damage_cooldown: float = 1.0  # Cooldown for dealing damage (seconds)
@export var damage_amount: int = 1  # Number of lives to take

var can_damage: bool = true
var damage_timer: Timer

func _ready():
	# Check player's collision_layer
	await get_tree().process_frame  # Wait until player is loaded
	var player = get_tree().get_first_node_in_group("player")

	# Connect body_entered signal
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Create damage cooldown timer
	damage_timer = Timer.new()
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_cooldown_timeout)
	add_child(damage_timer)

func _on_body_entered(body: Node2D):
	# Check if it's the player
	if body.is_in_group("player"):
		print("  -> Player detected! Applying damage")
		apply_trap_damage(body)
	else:
		print("  -> Not a player, ignoring damage")

func _on_body_exited(body: Node2D):
	# Reset cooldown when player exits
	if body.is_in_group("player"):
		can_damage = true
		if damage_timer.is_stopped() == false:
			damage_timer.stop()

func apply_trap_damage(player: Node2D):
	# Ignore damage during cooldown
	if not can_damage:
		return

	# Deal damage to player
	if player.has_method("lose_life"):
		for i in range(damage_amount):
			player.lose_life()
		print("Booby trap triggered! Player took damage.")

		# Start cooldown
		can_damage = false
		damage_timer.wait_time = damage_cooldown
		damage_timer.start()

func _on_damage_cooldown_timeout():
	can_damage = true
