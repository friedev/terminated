extends CharacterBody2D
class_name Bullet

@export var damage: int
@export var speed: float
@export var knockback: float
@export var stun: float


func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider() is Enemy:
			var enemy: Enemy = collision.get_collider()
			enemy.health -= damage
		# Always destroyed in a collision
		queue_free()
