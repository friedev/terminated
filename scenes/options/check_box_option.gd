extends Option
class_name CheckBoxOption

@export var default: bool

@export_group("Internal Nodes")
@export var check_box: CheckBox


func _ready() -> void:
	self.set_option(self.default, false)


func get_option() -> Variant:
	return self.check_box.button_pressed


func set_option(value: Variant, emit := true) -> void:
	if not value is bool:
		return
	var cast_value: bool = value
	self.check_box.set_pressed_no_signal(cast_value)
	super.set_option(cast_value, emit)


func _on_check_box_toggled(button_pressed: bool) -> void:
	self.set_option(button_pressed)
