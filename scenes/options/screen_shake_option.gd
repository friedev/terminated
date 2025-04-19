extends CheckBoxOption
class_name ScreenShakeOption


func get_option() -> Variant:
	return Globals.screen_shake_enabled


func set_option(value: Variant, emit := true) -> void:
	if not value is bool:
		return
	var cast_value: bool = value
	Globals.screen_shake_enabled = cast_value
	super.set_option(cast_value, emit)
