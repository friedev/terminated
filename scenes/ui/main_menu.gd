extends Control

signal play_pressed

@export var default_focus: Control
@export var submenu_button_group: ButtonGroup

@export_group("Internal Nodes")
@export var help_menu: Control
@export var options_menu: Control
@export var credits_menu: Control


func _ready() -> void:
	open_menu()


func open_menu() -> void:
	show()
	help_menu.hide()
	options_menu.hide()
	credits_menu.hide()
	default_focus.grab_focus()


func _on_main_game_started() -> void:
	hide()


func _on_player_died() -> void:
	open_menu()
	

func _on_play_button_pressed() -> void:
	play_pressed.emit()
	

func _on_help_button_toggled(toggled_on: bool) -> void:
	help_menu.visible = toggled_on
	

func _on_options_button_toggled(toggled_on: bool) -> void:
	options_menu.visible = toggled_on
	

func _on_credits_button_toggled(toggled_on: bool) -> void:
	credits_menu.visible = toggled_on
	

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var pressed_button := submenu_button_group.get_pressed_button()
		if pressed_button != null:
			pressed_button.button_pressed = false
			pressed_button.grab_focus()