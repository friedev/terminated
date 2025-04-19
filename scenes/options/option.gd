extends Control
class_name Option

signal changed(value: Variant)

@export var key: String


func get_option() -> Variant:
	return null


func set_option(value: Variant, emit := true) -> void:
	if emit:
		self.changed.emit(value)
