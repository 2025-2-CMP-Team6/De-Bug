# RangedEnemy.gd 
extends BaseEnemy

#region Bullet Firing
const BULLET_SCENE = preload("res://Actors/Enemies/bullet.tscn")
@onready var fire_timer = $FireTimer
@onready var muzzle = $Muzzle
#endregion

func _ready():
	super._ready()
	
	# Bullet firing timer
	if fire_timer != null:
		for conn in fire_timer.timeout.get_connections():
			fire_timer.timeout.disconnect(conn.callable)
		fire_timer.timeout.connect(shoot)

# Attack pattern
func shoot():
	if current_health <= 0: return
	
	var random_angle = randf_range(0, TAU)
	var direction = Vector2.RIGHT.rotated(random_angle)
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = direction
	
	if muzzle:
		bullet.global_position = muzzle.global_position
	else:
		bullet.global_position = global_position
		
	get_parent().add_child(bullet)

func die():
	if fire_timer != null:
		fire_timer.stop()
	super.die()
