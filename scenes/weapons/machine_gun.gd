extends Weapon

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

func fire() -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	super.spawn_projectile(bullet)
	bullet.velocity = (
		wielder.velocity
		+ Vector2(cos(bullet.rotation), sin(bullet.rotation)) * bullet.speed
	)
	super.fire()
