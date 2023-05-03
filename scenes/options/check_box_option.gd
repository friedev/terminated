extends Option
class_name CheckBoxOption

@export var default: bool

@onready var check_box: CheckBox = %CheckBox


func _ready() -> void:
	self.set_option(self.default, false)


func get_option() -> bool:
	return self.check_box.button_pressed


func set_option(value: bool, emit := true) -> void:
	self.check_box.set_pressed_no_signal(value)
	super.set_option(value, emit)


func _on_check_box_toggled(button_pressed: bool) -> void:
	self.set_option(button_pressed)
