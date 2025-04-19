extends CheckBoxOption
class_name AudioOption

@export var bus_name: StringName

@onready var bus_index := AudioServer.get_bus_index(self.bus_name)


func get_option() -> Variant:
	return not AudioServer.is_bus_mute(self.bus_index)


func set_option(value: Variant, emit := true) -> void:
	if not value is bool:
		return
	var cast_value: bool = value
	AudioServer.set_bus_mute(self.bus_index, not cast_value)
	super.set_option(cast_value, emit)
