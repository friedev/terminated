extends Button


func _ready() -> void:
	self.visible = OS.get_name() != "Web"