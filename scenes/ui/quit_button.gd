extends Button


func _ready() -> void:
	visible = OS.get_name() != "Web"