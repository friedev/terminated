extends CharacterBody2D
class_name Bullet

@export var damage: int
@export var speed: float
@export var knockback: float
@export var stun: float


func _physics_process(delta: float) -> void:
	var collision := self.move_and_collide(self.velocity * delta)
	if collision:
		if collision.get_collider() is Enemy:
			var enemy: Enemy = collision.get_collider()
			enemy.health -= damage
		elif collision.get_collider() is TileMap:
			# TODO merge with other implementations
			var tilemap: TileMap = collision.get_collider()
			var cellv := Vector2i(
				Vector2(tilemap.local_to_map(position)) - collision.get_normal()
			)
			var tile_id := tilemap.get_cell_atlas_coords(0, cellv).x
			if 0 < tile_id and tile_id < 9:
				var new_tile_id := tile_id - 1
				if new_tile_id <= 0:
					new_tile_id = -1
				# TODO flip tiles
				#var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
				#var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
				tilemap.set_cell(0, cellv, 0, Vector2i(new_tile_id, 0))
		# Always destroyed in a collision
		self.queue_free()
