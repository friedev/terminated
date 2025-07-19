extends Weapon

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@export var bullet_count: int
@export var spread_degrees: float

var spread: float:
	get:
		return deg_to_rad(spread_degrees)

func fire() -> void:
	for i in range(bullet_count):
		var bullet: Bullet = BULLET_SCENE.instantiate()
		super.spawn_projectile(bullet)
		bullet.rotation += (randf() * spread) - (spread * 0.5)
		bullet.velocity = (
			wielder.velocity
			+ Vector2(cos(bullet.rotation), sin(bullet.rotation)) * bullet.speed
		)
	super.fire()
