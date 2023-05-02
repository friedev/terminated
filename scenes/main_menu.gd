extends Control
class_name MainMenu

signal screen_shake_toggled(enabled: bool)

@onready var sound_bus_index = AudioServer.get_bus_index("Sound")
@onready var music_bus_index = AudioServer.get_bus_index("Music")

@onready var fullscreen_check_box = %FullscreenCheckBox


func update_fullscreen_status():
	var window_mode := self.get_window().mode
	self.fullscreen_check_box.button_pressed = (
		window_mode == Window.MODE_FULLSCREEN
		or window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	)

func _process(delta: float) -> void:
	# Ideally this would trigger via a signal or notification, but I can't find
	# one that deals with window mode changes
	# Tried:
	# - NOTIFICATION_WM_SIZE_CHANGED
	# - Window.titlebar_changed
	# - Viewport.size_changed
	self.update_fullscreen_status()


func _on_sound_check_box_toggled(button_pressed: bool) -> void:
	AudioServer.set_bus_mute(self.sound_bus_index, not button_pressed)


func _on_music_check_box_toggled(button_pressed: bool) -> void:
	AudioServer.set_bus_mute(self.music_bus_index, not button_pressed)


func _on_fullscreen_check_box_toggled(button_pressed: bool) -> void:
	self.get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if button_pressed else Window.MODE_WINDOWED


func _on_screen_shake_checkbox_toggled(button_pressed: bool):
	self.screen_shake_toggled.emit(button_pressed)

