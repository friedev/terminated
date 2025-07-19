extends Enemy
class_name LaserEnemy

const LASER_BEAM_SCENE := preload("res://scenes/laser_beam.tscn")

@export var laser_damage: int
@export var laser_range: float
@export var laser_shot_color: Color
@export var laser_charge_color: Color

@export_group("Internal Nodes")
@export var shapecast: ShapeCast2D
@export var cooldown_timer: Timer
@export var charge_timer: Timer
@export var laser_particles: GPUParticles2D
@export var laser_sound: AudioStreamPlayer2D

func _ready() -> void:
	super._ready()
	cooldown_timer.start()


func is_charging() -> bool:
	return not charge_timer.is_stopped()


func _physics_process(_delta: float) -> void:
	if not is_charging():
		var target_rotation := angle_to_player()
		rotation = lerp_angle(rotation, target_rotation, 0.1)


func fire_laser() -> void:
	# TODO merge with player laser implementation: give LaserEnemy a Laser node
	var laser_start := global_position
	var laser_end := (
		shapecast.target_position.rotated(shapecast.global_rotation)
		+ global_position
	)

	var collision_point: Vector2
	shapecast.force_shapecast_update()
	while shapecast.is_colliding():
		collision_point = shapecast.get_collision_point(0)
		laser_end = collision_point
		var object_hit := shapecast.get_collider(0)

		var player_hit := object_hit as Player
		if player_hit != null:
			player_hit.die()
			shapecast.add_exception(player_hit)
			shapecast.force_shapecast_update()
			continue

		var enemy_hit := object_hit as Enemy
		if enemy_hit != null:
			enemy_hit.health -= laser_damage
			# Don't penetrate large enemies
			if enemy_hit.max_health > 1:
				break
			shapecast.add_exception(enemy_hit)
			shapecast.force_shapecast_update()
			continue

		if object_hit is TileMapLayer:
			break

		assert(false, "Unhandled collision")
		break
	shapecast.clear_exceptions()

	var laser_beam: LaserBeam = LASER_BEAM_SCENE.instantiate()
	SignalBus.node_spawned.emit(laser_beam)
	laser_beam.add_point(laser_start)
	laser_beam.add_point(laser_end)
	laser_beam.default_color = laser_shot_color
	destroyed.connect(laser_beam.hide)

	laser_sound.pitch_scale = 1 + (randf() - 0.5) * 0.25
	laser_sound.play()
	laser_particles.restart()


func _on_cooldown_timer_timeout() -> void:
	charge_timer.start()

	var target_position := Vector2(laser_range, 0)
	shapecast.target_position = target_position

	var laser_start := global_position
	var laser_end := global_position + target_position.rotated(rotation)

	var laser_beam: LaserBeam = LASER_BEAM_SCENE.instantiate()
	laser_beam.reverse = true
	laser_beam.duration = cooldown_timer.time_left
	SignalBus.node_spawned.emit(laser_beam)
	laser_beam.add_point(laser_start)
	laser_beam.add_point(laser_end)
	laser_beam.default_color = laser_charge_color


func _on_charge_timer_timeout() -> void:
	cooldown_timer.start()
	fire_laser()
