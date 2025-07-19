class_name CheckBoxOption extends Option

@export var default: bool
@export var toggle_input_action := ""

@export var check_box: CheckBox


func _ready() -> void:
	super._ready()
	if self.toggle_input_action == "":
		var default_input_action := "toggle_%s" % self.key
		if InputMap.has_action(default_input_action):
			self.toggle_input_action = default_input_action


func get_option() -> bool:
	return self.check_box.button_pressed


func set_option(value: bool, emit := true) -> void:
	self.check_box.set_pressed_no_signal(value)
	super.set_option(value, emit)


func _on_check_box_toggled(button_pressed: bool) -> void:
	self.set_option(button_pressed)


func _input(event: InputEvent) -> void:
	# TODO save new setting?
	if self.toggle_input_action != "" and event.is_action_pressed(self.toggle_input_action):
		self.set_option(not self.get_option())
