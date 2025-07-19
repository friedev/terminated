extends CharacterBody2D
class_name Enemy

@export var acceleration: float
@export var max_speed: float
@export var max_health: int

@export var death_effect_scene: PackedScene
@export var debris_scene: PackedScene

# If velocity is below this threshold, face the player instead of facing the velocity
const velocity_threshold := 10.0

@export_group("Internal Nodes")
@export var sprite: AnimatedSprite2D
@export var ambient_sound: AudioStreamPlayer2D
@export var hurt_sound: AudioStreamPlayer2D
@export var damage_particles: GPUParticles2D

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


func _ready() -> void:
	self.ambient_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	self.ambient_sound.play(randf() * self.ambient_sound.stream.get_length())


func _process(_delta: float) -> void:
	self.sprite.speed_scale = self.velocity.length() / self.max_speed


func _physics_process(_delta: float) -> void:
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
		(collider as Player).die()
		return

	if collider is Enemy:
		var enemy: Enemy = collider
		if self.max_health > 1 and enemy.max_health == 1:
			enemy.die()
		elif self.max_health == 1 and enemy.max_health > 1:
			self.die()
		return

	if collider is TileMapLayer and self.max_health == 1:
		self.die()
		return


func angle_to_player() -> float:
	return self.global_position.angle_to_point(Player.instance.global_position)


func direction_to_player() -> Vector2:
	return Vector2(1, 0).rotated(self.angle_to_player())


func die() -> void:
	var death_effect: DeathEffect = self.death_effect_scene.instantiate()
	death_effect.global_position = self.global_position
	SignalBus.node_spawned.emit(death_effect)

	var debris: Node2D = self.debris_scene.instantiate()
	debris.global_position = self.global_position
	debris.rotation = randf() * (2 * PI)
	SignalBus.node_spawned.emit(debris)

	self.queue_free()
