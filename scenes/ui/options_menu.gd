extends VBoxContainer


func _on_save_button_pressed() -> void:
	Options.save_config()


func _on_undo_button_pressed() -> void:
	Options.load_config()


func _on_defaults_button_pressed() -> void:
	Options.apply_defaults()