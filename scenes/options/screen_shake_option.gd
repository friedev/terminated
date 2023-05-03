extends CheckBoxOption
class_name ScreenShakeOption


func get_option() -> bool:
	return Globals.screen_shake_enabled


func set_option(value: bool, emit := true) -> void:
	Globals.screen_shake_enabled = value
	super.set_option(value, emit)
