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
	noise.seed = randi()
	SignalBus.screen_shake.connect(_on_screen_shake)


func apply_shake(delta: float) -> void:
	var noise_position := Time.get_ticks_msec() * shake_rate
	var x := noise.get_noise_1d(noise_position)
	var y := noise.get_noise_1d(-noise_position)
	var screen_shake_setting: float = Options.options["screen_shake"]
	offset = Vector2(x, y) * max_offset * (shake ** 2) * screen_shake_setting
	shake -= shake_reduction * delta


func _process(delta: float) -> void:
	apply_shake(delta)


func _on_screen_shake(new_shake: float) -> void:
	shake = maxf(shake, new_shake)
