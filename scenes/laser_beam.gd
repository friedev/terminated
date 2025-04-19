extends Line2D
class_name LaserBeam

var max_width := 4.0
var duration := 0.5
var reverse := false

@export_group("Internal Nodes")
@export var timer: Timer


func _ready() -> void:
	self.timer.start(self.duration)


func _process(_delta: float) -> void:
	var strength := self.timer.time_left / self.timer.wait_time
	if self.reverse:
		strength = 1.0 - strength
	self.width = self.max_width * strength


func _on_timer_timeout() -> void:
	self.queue_free()
