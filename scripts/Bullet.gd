extends CharacterBody2D

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
	if collision:
		if collision.get_collider().is_in_group(&"enemies"):
			var enemy = collision.get_collider()
			enemy.damage_by(damage, (enemy.position - self.position).normalized() * knockback, stun)
		elif collision.get_collider() is TileMap:
			# TODO merge with other implementations
			var tilemap = collision.get_collider()
			var cellv = Vector2i(Vector2(tilemap.local_to_map(position)) - collision.get_normal())
			var tile_id = tilemap.get_cell_atlas_coords(0, cellv).x
			if 0 < tile_id and tile_id < 9:
				var new_tile_id = tile_id - 1
				if new_tile_id <= 0:
					new_tile_id = -1
				# TODO flip tiles
				#var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
				#var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
				tilemap.set_cell(0, cellv, 0, Vector2i(new_tile_id, 0))
		if not collision.get_collider().is_in_group(&"bullets"):
			queue_free()
	elif initial_position.distance_to(position) > max_range:
		queue_free()
