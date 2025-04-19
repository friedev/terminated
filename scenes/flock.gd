extends Node


var flock_center := Vector2()
var flock_heading := Vector2()


func _physics_process(delta: float) -> void:
	# Calculate flock parameters here to avoid recomputing for every flockmate
	# Reduces time complexity from O(n^2) to O(n)
	var flock = self.get_tree().get_nodes_in_group("flock")
	self.flock_center = Vector2()
	self.flock_heading = Vector2()
	for flockmate in flock:
		self.flock_heading += Vector2(1, 0).rotated(flockmate.rotation)
		self.flock_center += flockmate.position

	if len(flock) > 0:
		self.flock_heading /= len(flock)
		self.flock_center /= len(flock)
