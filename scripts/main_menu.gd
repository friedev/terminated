extends Control

signal screen_shake_toggled(enabled: bool)

@onready var sound_bus_index = AudioServer.get_bus_index("Sound")
@onready var music_bus_index = AudioServer.get_bus_index("Music")

@onready var fullscreen_check_box = %FullscreenCheckBox


func _ready() -> void:
	self.fullscreen_check_box.button_pressed = OS.get_name() != "HTML5"


func _on_sound_check_box_toggled(button_pressed: bool) -> void:
	AudioServer.set_bus_mute(self.sound_bus_index, not button_pressed)


func _on_music_check_box_toggled(button_pressed: bool) -> void:
	AudioServer.set_bus_mute(self.music_bus_index, not button_pressed)


func _on_fullscreen_check_box_toggled(button_pressed: bool) -> void:
	self.get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if button_pressed else Window.MODE_WINDOWED


func _on_screen_shake_checkbox_toggled(button_pressed: bool):
	self.screen_shake_toggled.emit(button_pressed)

