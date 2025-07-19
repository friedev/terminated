extends Enemy
class_name BombEnemy

@export var damage: int

@export_group("Internal Nodes")
@export var bomb_area: Area2D


func _process(_delta: float) -> void:
	self.bomb_area.global_rotation = 0


func die() -> void:
	for body in self.bomb_area.get_overlapping_bodies():
		if body is Player:
			(body as Player).die()
			continue

		var enemy := body as Enemy
		# Be careful of mutual recursion when a bomb blows up another bomb
		if enemy != null and enemy.health > 0 and enemy != self:
			enemy.health -= damage
			continue

	super.die()
