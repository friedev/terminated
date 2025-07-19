class_name SliderOption extends Option

@export var default: float

@export var slider: Slider


func get_default() -> Variant:
	return self.default


func get_option() -> float:
	return self.slider.value


func set_option(value: Variant, emit := true) -> bool:
	if not value is float:
		assert(false)
		return false
	self.slider.set_value_no_signal(value as float)
	return super.set_option(value, emit)


func _on_slider_value_changed(value: float) -> void:
	self.set_option(value)