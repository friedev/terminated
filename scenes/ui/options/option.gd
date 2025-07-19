class_name Option extends Control

signal changed(value: Variant)

@export var key: String


func _ready() -> void:
	if self.key in Options.options:
		self.set_option(Options.options[self.key], false)


func get_default() -> Variant:
	assert(false, "Abstract function called")
	return null


func get_option() -> Variant:
	return Options.options[self.key]


func set_option(value: Variant, emit := true) -> bool:
	Options.options[self.key] = value
	if emit:
		self.changed.emit(value)
	return true