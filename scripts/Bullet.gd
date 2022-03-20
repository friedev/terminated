extends KinematicBody2D

onready var player: KinematicBody2D = get_tree().get_root().find_node("Player", true, false)

var damage: int
var speed: float
var max_range: float
var knockback: float
var stun: float

var initial_position := Vector2()
var initial_velocity := Vector2()


func _ready():
	add_to_group("bullets")


func _physics_process(delta: float):
	var velocity := initial_velocity + Vector2(cos(self.rotation), sin(self.rotation)) * speed
	var collision := move_and_collide(velocity * delta)
	if collision and collision.collider != player:
		if collision.collider.is_in_group("enemies"):
			var enemy = collision.collider
			enemy.damage(damage, (enemy.position - self.position).normalized() * knockback, stun)
		elif collision.collider is TileMap:
			# TODO merge with other implementations
			var tilemap = collision.collider
			var cellv = tilemap.world_to_map(position) - collision.normal
			var tile_id = tilemap.get_cellv(cellv)
			if 0 < tile_id and tile_id < 9:
				var new_tile_id = max(0, tile_id - 1)
				var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
				var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
				tilemap.set_cellv(cellv, new_tile_id, flip_x, flip_y)
		if not collision.collider.is_in_group("bullets"):
			queue_free()
	elif initial_position.distance_to(position) > max_range:
		queue_free()
