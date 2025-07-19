extends CharacterBody2D
class_name Enemy

signal destroyed

@export var acceleration: float
@export var max_speed: float
@export var max_health: int

@export var death_effect_scene: PackedScene
@export var debris_scene: PackedScene

# If velocity is below this threshold, face the player instead of facing the velocity
const velocity_threshold := 10.0

@export_group("Spawning")
@export var difficulty: int
## The first wave in which this enemy can spawn.
@export var min_wave: int
## Chance to be spawned relative to other enemies.
@export var weight: float

@export_group("Internal Nodes")
@export var sprite: AnimatedSprite2D
@export var ambient_sound: AudioStreamPlayer2D
@export var hurt_sound: AudioStreamPlayer2D
@export var damage_particles: GPUParticles2D

@onready var health := max_health:
	set(value):
		if value < health:
			hurt_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
			hurt_sound.play()
			damage_particles.restart()

		health = clamp(value, 0, max_health)

		if health <= 0:
			die()
			return


func _ready() -> void:
	ambient_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	ambient_sound.play(randf() * ambient_sound.stream.get_length())


func _process(_delta: float) -> void:
	sprite.speed_scale = velocity.length() / max_speed


func _physics_process(_delta: float) -> void:
	var target_direction := get_target_direction()
	velocity += target_direction * acceleration
	velocity = velocity.limit_length(max_speed)

	if velocity.length() > velocity_threshold:
		rotation = velocity.angle()
	else:
		rotation = target_direction.angle()

	move_and_slide()
	for slide_index in range(get_slide_collision_count()):
		handle_collision(get_slide_collision(slide_index))


func get_target_direction() -> Vector2:
	return direction_to_player()


func handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider is Player:
		(collider as Player).die()
		return

	if collider is Enemy:
		var enemy: Enemy = collider
		if max_health > 1 and enemy.max_health == 1:
			enemy.die()
		elif max_health == 1 and enemy.max_health > 1:
			die()
		return

	if collider is TileMapLayer and max_health == 1:
		die()
		return


func angle_to_player() -> float:
	return global_position.angle_to_point(Player.instance.global_position)


func direction_to_player() -> Vector2:
	return Vector2.RIGHT.rotated(angle_to_player())


func die() -> void:
	if is_queued_for_deletion():
		return
	
	var death_effect: DeathEffect = death_effect_scene.instantiate()
	death_effect.global_position = global_position
	SignalBus.node_spawned.emit(death_effect)

	var debris: Node2D = debris_scene.instantiate()
	debris.global_position = global_position
	debris.rotation = randf() * (2 * PI)
	SignalBus.node_spawned.emit(debris)

	queue_free()
	destroyed.emit()
