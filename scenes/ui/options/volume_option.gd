class_name VolumeOption extends SliderOption

@export var bus_name: StringName

@onready var bus_index := AudioServer.get_bus_index(self.bus_name)


func get_option() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(self.bus_index))


func set_option(value: Variant, emit := true) -> bool:
	if super.set_option(value, emit):
		AudioServer.set_bus_volume_db(self.bus_index, linear_to_db(value as float))
		return true
	return false
