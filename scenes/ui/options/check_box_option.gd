class_name CheckBoxOption extends Option

@export var default: bool
@export var toggle_input_action := ""

@export var check_box: CheckBox


func _ready() -> void:
	super._ready()
	if toggle_input_action == "":
		var default_input_action := "toggle_%s" % key
		if InputMap.has_action(default_input_action):
			toggle_input_action = default_input_action


func get_default() -> Variant:
	return default


func get_option() -> bool:
	return check_box.button_pressed


func set_option(value: Variant) -> bool:
	if not value is bool:
		assert(false)
		return false
	check_box.set_pressed_no_signal(value as bool)
	return super.set_option(value)


func _on_check_box_toggled(button_pressed: bool) -> void:
	set_option(button_pressed)


func _input(event: InputEvent) -> void:
	# TODO save new setting?
	if toggle_input_action != "" and event.is_action_pressed(toggle_input_action):
		set_option(not get_option())
