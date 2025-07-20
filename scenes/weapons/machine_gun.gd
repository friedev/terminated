extends Weapon

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

func fire(fire_angle: float) -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	SignalBus.node_spawned.emit(bullet)
	bullet.global_position = projectile_spawn_point.global_position
	bullet.global_rotation = fire_angle
	bullet.velocity = (
		wielder.velocity
		+ Vector2(cos(bullet.rotation), sin(bullet.rotation)) * bullet.speed
	)
	super.fire(fire_angle)
