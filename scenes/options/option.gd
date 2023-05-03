extends Control
class_name Option

signal changed(value)

@export var key: String


func get_option():
	return null


func set_option(value, emit := true) -> void:
	if emit:
		self.changed.emit(value)
