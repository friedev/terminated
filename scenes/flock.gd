extends Node


var flock_center := Vector2()
var flock_heading := Vector2()


func _physics_process(_delta: float) -> void:
	# Calculate flock parameters here to avoid recomputing for every flockmate
	# Reduces time complexity from O(n^2) to O(n)
	var flock := get_tree().get_nodes_in_group("flock")
	flock_center = Vector2()
	flock_heading = Vector2()
	for flockmate: Node2D in flock:
		flock_heading += Vector2(1, 0).rotated(flockmate.rotation)
		flock_center += flockmate.position

	if len(flock) > 0:
		flock_heading /= len(flock)
		flock_center /= len(flock)
