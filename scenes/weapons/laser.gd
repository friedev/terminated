extends Weapon

const LASER_BEAM_SCENE := preload("res://scenes/laser_beam.tscn")

@export var damage: int
@export var max_range: float
@export var knockback: float
@export var stun: float
@export var color: Color

@export_group("Internal Nodes")
@export var shapecast: ShapeCast2D

func fire() -> void:
	# TODO merge with enemy laser implementation: give LaserEnemy a Laser node
	var laser_start := self.global_position
	var laser_end := (
		self.shapecast.target_position.rotated(self.shapecast.global_rotation)
		+ self.global_position
	)

	self.shapecast.look_at(self.get_global_mouse_position())
	self.shapecast.target_position = Vector2(self.max_range, 0)
	self.shapecast.force_shapecast_update()
	var collision_point: Vector2
	while self.shapecast.is_colliding():
		self.shapecast.force_shapecast_update()
		collision_point = self.shapecast.get_collision_point(0)
		laser_end = collision_point
		var object_hit = self.shapecast.get_collider(0)

		var enemy_hit = object_hit as Enemy
		if enemy_hit != null:
			enemy_hit.health -= self.damage
			# Don't penetrate large enemies
			if enemy_hit.max_health > 1:
				break
			self.shapecast.add_exception(object_hit)
			continue

		var tilemap_hit = object_hit as TileMap
		if tilemap_hit != null:
			break
	self.shapecast.clear_exceptions()

	var laser_beam: LaserBeam = self.LASER_BEAM_SCENE.instantiate()
	self.wielder.add_sibling(laser_beam)
	laser_beam.add_point(laser_start)
	laser_beam.add_point(laser_end)
	laser_beam.default_color = self.color

	super.fire()
