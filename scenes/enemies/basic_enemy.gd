extends Enemy
class_name BasicEnemy

# Flock parameters
@export var inertia_weight: float
@export var separation_weight: float
@export var alignment_weight: float
@export var cohesion_weight: float
@export var player_weight: float
@export var separation_distance: float
@export var flock_radius: float

@export_group("Internal Nodes")
@export var separation_area: Area2D


func get_flock_center() -> Vector2:
	return Flock.flock_center


func get_flock_separation() -> Vector2:
	var separation := Vector2()
	for body in separation_area.get_overlapping_bodies():
		if body == self:
			continue
		var distance := position.distance_to(body.position)
		separation -= (
			(body.position - position).normalized()
			* (separation_distance / distance)
		)
	return separation


func get_flock_heading() -> Vector2:
	return Flock.flock_heading


func get_flock_cohesion() -> Vector2:
	return (get_flock_center() - position) / flock_radius


# Adapted from Vinicius Gerevini's Godot Boids implementation (MIT license):
# https://github.com/viniciusgerevini/godot-boids
func get_flock_direction() -> Vector2:
	var direction := Vector2(1, 0).rotated(rotation)
	var player_direction := direction_to_player()
	var separation := get_flock_separation()
	var heading := get_flock_heading()
	var cohesion := get_flock_cohesion()

	var flock_direction := (
		direction * inertia_weight
		+ player_direction * player_weight
		+ separation * separation_weight
		+ heading * alignment_weight
		+ cohesion * cohesion_weight
	)

	return flock_direction.normalized()


func get_target_direction() -> Vector2:
	return get_flock_direction()
