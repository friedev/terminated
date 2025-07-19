class_name Option extends Control

signal changed(value: Variant)

@export var key: String


func _ready() -> void:
	if key in Options.options:
		set_option(Options.options[key], false)


func get_default() -> Variant:
	assert(false, "Abstract function called")
	return null


func get_option() -> Variant:
	return Options.options[key]


func set_option(value: Variant, emit := true) -> bool:
	Options.options[key] = value
	if emit:
		changed.emit(value)
	return true