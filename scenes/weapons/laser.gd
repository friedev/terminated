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
	var laser_start := global_position
	var laser_end := (
		shapecast.target_position.rotated(shapecast.global_rotation)
		+ global_position
	)

	shapecast.look_at(get_global_mouse_position())
	shapecast.target_position = Vector2(max_range, 0)
	shapecast.force_shapecast_update()
	var collision_point: Vector2
	while shapecast.is_colliding():
		collision_point = shapecast.get_collision_point(0)
		laser_end = collision_point
		var object_hit := shapecast.get_collider(0)

		var enemy_hit := object_hit as Enemy
		if enemy_hit != null:
			enemy_hit.health -= damage
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
	laser_beam.default_color = color

	super.fire()
