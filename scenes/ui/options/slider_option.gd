class_name SliderOption extends Option

@export var default: float

@export var slider: Slider


func get_default() -> Variant:
	return default


func get_option() -> float:
	return slider.value


func set_option(value: Variant) -> bool:
	if not value is float:
		assert(false)
		return false
	slider.set_value_no_signal(value as float)
	return super.set_option(value)


func _on_slider_value_changed(value: float) -> void:
	set_option(value)