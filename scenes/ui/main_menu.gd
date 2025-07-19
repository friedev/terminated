extends Control

signal play_pressed

@export var default_focus: Control

@export_group("Internal Nodes")
@export var help_menu: Control
@export var options_menu: Control
@export var credits_menu: Control


func _ready() -> void:
	self.show()
	self.help_menu.hide()
	self.options_menu.hide()
	self.credits_menu.hide()
	self.default_focus.grab_focus()


func _on_main_game_started() -> void:
	self.hide()
	

func _on_play_button_pressed() -> void:
	self.play_pressed.emit()
	

func _on_help_button_toggled(toggled_on: bool) -> void:
	self.help_menu.visible = toggled_on
	

func _on_options_button_toggled(toggled_on: bool) -> void:
	self.options_menu.visible = toggled_on
	

func _on_credits_button_toggled(toggled_on: bool) -> void:
	self.credits_menu.visible = toggled_on
	

func _on_quit_button_pressed() -> void:
	self.get_tree().quit()
