extends Enemy
class_name BombEnemy

@export var damage: int

@export_group("Internal Nodes")
@export var bomb_area: Area2D


func _process(delta: float) -> void:
	self.bomb_area.global_rotation = 0


func die():
	for body in self.bomb_area.get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.die()
			continue

		var enemy := body as Enemy
		# Be careful of mutual recursion when a bomb blows up another bomb
		if enemy != null and enemy.health > 0 and enemy != self:
			enemy.health -= damage
			continue

	super.die()
