extends Weapon

const LASER_BEAM_SCENE := preload("res://scenes/laser_beam.tscn")

@export var damage: int
@export var max_range: float
@export var knockback: float
@export var stun: float
@export var color: Color

@onready var shapecast: ShapeCast2D = %ShapeCast2D

func fire() -> void:
	# TODO merge with enemy laser implementation
	self.shapecast.look_at(self.get_global_mouse_position())
	self.shapecast.target_position = Vector2(self.max_range, 0)
	self.shapecast.force_shapecast_update()
	var collision_point: Vector2
	while self.shapecast.is_colliding():
		collision_point = self.shapecast.get_collision_point(0)
		var object_hit = self.shapecast.get_collider(0)
		if object_hit.is_in_group(&"enemies"):
			object_hit.damage_by(
				self.damage,
				(object_hit.position - self.position).normalized() * self.knockback,
				self.stun
			)
			# Don't penetrate large enemies
			if object_hit.max_health > 1:
				break
		elif object_hit is TileMap:
			# TODO merge with other implementations
			var tilemap = object_hit
			var position_hit = (
				collision_point
				+ Vector2(object_hit.tile_set.tile_size.x / 2, 0)
				.rotated(self.shapecast.global_rotation)
			)
			var cellv = object_hit.local_to_map(position_hit)
			var tile_id = tilemap.get_cell_atlas_coords(0, cellv).x
			if 0 < tile_id and tile_id < 9:
				var new_tile_id = tile_id - 9
				if new_tile_id <= 0:
					new_tile_id = -1
				# TODOO flip tiles
				#var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
				#var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
				tilemap.set_cell(0, cellv, 0, Vector2i(new_tile_id, 0))
			break
		self.shapecast.add_exception(object_hit)
		self.shapecast.force_shapecast_update()

	self.shapecast.clear_exceptions()
	var laser_start := self.global_position
	var laser_end: Vector2
	if self.shapecast.is_colliding():
		laser_end = collision_point
	else:
		laser_end = (
			self.shapecast.target_position.rotated(self.shapecast.global_rotation)
			+ self.global_position
		)

	var laser_beam: LaserBeam = self.LASER_BEAM_SCENE.instantiate()
	self.wielder.get_parent().add_child(laser_beam)
	laser_beam.add_point(laser_start)
	laser_beam.add_point(laser_end)
	laser_beam.default_color = self.color

	super.fire()
