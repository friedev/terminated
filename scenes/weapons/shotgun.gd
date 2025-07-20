extends Weapon

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@export var bullet_count: int
@export var spread_degrees: float

var spread: float:
	get:
		return deg_to_rad(spread_degrees)

func fire(fire_angle: float) -> void:
	for i in range(bullet_count):
		var bullet: Bullet = BULLET_SCENE.instantiate()
		SignalBus.node_spawned.emit(bullet)
		bullet.global_position = projectile_spawn_point.global_position
		bullet.global_rotation = fire_angle + randf_range(-0.5, +0.5) * spread
		bullet.velocity = (
			wielder.velocity
			+ Vector2(cos(bullet.rotation), sin(bullet.rotation)) * bullet.speed
		)
	super.fire(fire_angle)
