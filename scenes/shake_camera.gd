extends Camera2D
class_name ShakeCamera

@export var shake_rate: float
@export var max_offset: float
@export var shake_reduction: float

var shake := 0.0:
	set(value):
		shake = clamp(value, 0.0, 1.0)
var noise := FastNoiseLite.new()


func _ready() -> void:
	self.noise.seed = randi()


func apply_shake() -> void:
	if not Globals.screen_shake_enabled:
		self.shake = 0.0
	var noise_position := Time.get_ticks_msec() * self.shake_rate
	var x := self.noise.get_noise_1d(noise_position)
	var y := self.noise.get_noise_1d(-noise_position)
	self.offset = Vector2(x, y) * self.max_offset * (self.shake ** 2)
	self.shake -= self.shake_reduction


func _process(delta: float) -> void:
	self.apply_shake()
