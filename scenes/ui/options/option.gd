class_name Option extends Control

@export var key: String


func _ready() -> void:
	if key in Options.options:
		set_option(Options.options[key])


func get_default() -> Variant:
	assert(false, "Abstract function called")
	return null


func get_option() -> Variant:
	return Options.options[key]


func set_option(value: Variant) -> bool:
	Options.options[key] = value
	SignalBus.option_changed.emit(key, value)
	return true