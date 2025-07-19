extends Line2D
class_name LaserBeam

var max_width := 4.0
var duration := 0.5
var reverse := false

@export_group("Internal Nodes")
@export var timer: Timer


func _ready() -> void:
	timer.start(duration)
	update_strength()


func _process(_delta: float) -> void:
	update_strength()


func update_strength() -> void:
	var strength := timer.time_left / timer.wait_time
	if reverse:
		strength = 1.0 - strength
	width = max_width * strength


func _on_timer_timeout() -> void:
	queue_free()
