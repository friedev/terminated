extends Enemy
class_name LaserEnemy

const LASER_BEAM_SCENE := preload("res://scenes/laser_beam.tscn")

@export var laser_damage: int
@export var laser_range: float
@export var laser_shot_color: Color
@export var laser_charge_color: Color

@onready var shapecast: ShapeCast2D = %ShapeCast2D
@onready var cooldown_timer: Timer = %CooldownTimer
@onready var charge_timer: Timer = %ChargeTimer
@onready var laser_particles: GPUParticles2D = %LaserParticles
@onready var laser_sound: AudioStreamPlayer2D = %LaserSound

func _ready():
	super._ready()
	self.cooldown_timer.start()


func is_charging() -> bool:
	return not self.charge_timer.is_stopped()


func _physics_process(delta: float) -> void:
	if not self.is_charging():
		var target_rotation := (self.player.global_position - self.global_position).angle()
		self.rotation = lerp_angle(rotation, target_rotation, 0.1)


func fire_laser() -> void:
	# TODO merge with player laser implementation: give LaserEnemy a Laser node
	var laser_start := self.global_position
	var laser_end := (
		self.shapecast.target_position.rotated(self.shapecast.global_rotation)
		+ self.global_position
	)

	var collision_point: Vector2
	self.shapecast.force_shapecast_update()
	while self.shapecast.is_colliding():
		self.shapecast.force_shapecast_update()
		collision_point = self.shapecast.get_collision_point(0)
		laser_end = collision_point
		var object_hit = self.shapecast.get_collider(0)

		var player_hit := object_hit as Player
		if player_hit != null:
			player_hit.die()
			self.shapecast.add_exception(object_hit)
			continue

		var enemy_hit := object_hit as Enemy
		if enemy_hit != null:
			enemy_hit.health -= self.laser_damage
			# Don't penetrate large enemies
			if enemy_hit.max_health > 1:
				break
			self.shapecast.add_exception(object_hit)
			continue

		var tilemap_hit := object_hit as TileMap
		if tilemap_hit != null:
			# TODO merge with other implementations
			var position_hit = collision_point + Vector2(tilemap_hit.tile_set.tile_size.x / 2, 0).rotated(self.shapecast.global_rotation)
			var cellv = tilemap_hit.local_to_map(position_hit)
			var tile_id = tilemap_hit.get_cell_atlas_coords(0, cellv).x
			if 0 < tile_id and tile_id < 9:
				var new_tile_id = max(0, tile_id - 1)
				# TODO flip tiles
				#var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
				#var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
				tilemap_hit.set_cell(0, cellv, 0, Vector2i(new_tile_id, 0))
			break
	self.shapecast.clear_exceptions()

	var laser_beam: LaserBeam = self.LASER_BEAM_SCENE.instantiate()
	self.add_sibling(laser_beam)
	laser_beam.add_point(laser_start)
	laser_beam.add_point(laser_end)
	laser_beam.default_color = self.laser_shot_color

	self.laser_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	self.laser_sound.play()
	self.laser_particles.restart()


func _on_cooldown_timer_timeout():
	self.charge_timer.start()

	var target_position := Vector2(self.laser_range, 0)
	self.shapecast.target_position = target_position

	var laser_start := self.global_position
	var laser_end := self.global_position + target_position.rotated(self.rotation)

	var laser_beam: LaserBeam = self.LASER_BEAM_SCENE.instantiate()
	laser_beam.reverse = true
	laser_beam.duration = self.cooldown_timer.time_left
	self.add_sibling(laser_beam)
	laser_beam.add_point(laser_start)
	laser_beam.add_point(laser_end)
	laser_beam.default_color = self.laser_charge_color


func _on_charge_timer_timeout():
	self.cooldown_timer.start()
	self.fire_laser()