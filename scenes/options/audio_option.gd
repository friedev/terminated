extends CheckBoxOption
class_name AudioOption

@export var bus_name: StringName

@onready var bus_index := AudioServer.get_bus_index(self.bus_name)


func get_option() -> bool:
	return not AudioServer.is_bus_mute(self.bus_index)


func set_option(value: bool, emit := true) -> void:
	AudioServer.set_bus_mute(self.bus_index, not value)
	super.set_option(value, emit)
