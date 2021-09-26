extends KinematicBody2D

onready var player: KinematicBody2D = get_tree().get_root().find_node("Player", true, false)

var damage: int
var speed: float
var max_range: float
var knockback: float
var stun: float

var initial_position := Vector2()
var initial_velocity := Vector2()


func _physics_process(delta: float):
	var velocity := initial_velocity + Vector2(cos(self.rotation), sin(self.rotation)) * speed
	var collision := move_and_collide(velocity * delta)
	if collision and collision.collider != player:
		# TODO don't use string operations here (get_class/is_class won't work since they just use the native base class name)
		if "Enemy" in collision.collider.name:
			var enemy = collision.collider

			enemy.damage(damage, (enemy.position - self.position).normalized() * knockback, stun)
		if not "Bullet" in collision.collider.name:
			queue_free()
	elif initial_position.distance_to(position) > max_range:
		queue_free()
