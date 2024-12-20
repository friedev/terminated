extends CharacterBody2D
class_name Enemy

@export var acceleration: float
@export var max_speed: float
@export var max_health: int

@export var death_effect_scene: PackedScene
@export var debris_scene: PackedScene

# If velocity is below this threshold, face the player instead of facing the velocity
const velocity_threshold := 10.0

var player: Player

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var ambient_sound: AudioStreamPlayer2D = %AmbientSound
@onready var hurt_sound: AudioStreamPlayer2D = %HurtSound
@onready var damage_particles: GPUParticles2D = %DamageParticles

@onready var health := max_health:
	set(value):
		if value < self.health:
			self.hurt_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
			self.hurt_sound.play()
			self.damage_particles.restart()

		health = clamp(value, 0, self.max_health)

		if health <= 0:
			self.die()
			return


func _ready():
	self.ambient_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	self.ambient_sound.play(randf() * self.ambient_sound.stream.get_length())


func _process(delta: float) -> void:
	self.sprite.speed_scale = self.velocity.length() / self.max_speed


func _physics_process(delta: float):
	var target_direction := self.get_target_direction()
	self.velocity += target_direction * self.acceleration
	self.velocity = self.velocity.limit_length(self.max_speed)

	if self.velocity.length() > self.velocity_threshold:
		self.rotation = self.velocity.angle()
	else:
		self.rotation = target_direction.angle()

	self.move_and_slide()
	for slide_index in range(self.get_slide_collision_count()):
		self.handle_collision(self.get_slide_collision(slide_index))


func get_target_direction() -> Vector2:
	return self.direction_to_player()


func handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Player:
		var player: Player = collider
		player.die()
		return

	if collider is Enemy:
		var enemy: Enemy = collider
		if self.max_health > 1 and enemy.max_health == 1:
			enemy.die()
		elif self.max_health == 1 and enemy.max_health > 1:
			self.die()
		return

	if collider is TileMap:
		# TODO merge with other implementations
		var tilemap: TileMap = collider
		var cellv = tilemap.local_to_map(collision.get_position() + collision.get_travel())
		var tile_id = tilemap.get_cell_atlas_coords(0, cellv).x
		if 0 < tile_id and tile_id < 9:
			var damage: int
			if max_health == 1:
				damage = 1
			else:
				damage = 9
			var new_tile_id = tile_id - damage
			if new_tile_id <= 0:
				new_tile_id = -1
			# TODO flip tiles
			#var flip_x = tilemap.is_cell_x_flipped(cellv.x, cellv.y)
			#var flip_y = tilemap.is_cell_y_flipped(cellv.x, cellv.y)
			tilemap.set_cell(0, cellv, 0, Vector2i(new_tile_id, 0))
			#tilemap.update_dirty_quadrants()
		if self.max_health == 1:
			self.die()
			return


func direction_to_player() -> Vector2:
	return Vector2(1, 0).rotated(self.position.angle_to_point(self.player.position))


func die():
	var death_effect: DeathEffect = self.death_effect_scene.instantiate()
	death_effect.global_position = self.global_position
	self.add_sibling(death_effect)

	var debris: Node2D = self.debris_scene.instantiate()
	debris.global_position = self.global_position
	debris.rotation = randf() * (2 * PI)
	self.add_sibling(debris)

	self.queue_free()
