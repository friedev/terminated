class_name ShakeCamera extends Camera2D

## Frequency of shakes.
@export var shake_rate: float
## Maximum camera offset, in pixels, at 1.0 shake amplitude.
@export var max_offset: float
## Amount by which shake amplitude decreases per second.
@export var shake_reduction: float

## Current shake amplitude.
var shake := 0.0:
	set(value):
		shake = clamp(value, 0.0, 1.0)
var noise := FastNoiseLite.new()


func _ready() -> void:
	self.noise.seed = randi()
	SignalBus.screen_shake.connect(self._on_screen_shake)


func apply_shake(delta: float) -> void:
	if not Globals.screen_shake_enabled:
		self.shake = 0.0
	var noise_position := Time.get_ticks_msec() * self.shake_rate
	var x := self.noise.get_noise_1d(noise_position)
	var y := self.noise.get_noise_1d(-noise_position)
	self.offset = Vector2(x, y) * self.max_offset * (self.shake ** 2)
	self.shake -= self.shake_reduction * delta


func _process(delta: float) -> void:
	self.apply_shake(delta)


func _on_screen_shake(new_shake: float) -> void:
	self.shake = maxf(self.shake, new_shake)