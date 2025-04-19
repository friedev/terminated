extends Label


func _ready() -> void:
	self.text = "Version %s" % ProjectSettings.get_setting("application/config/version")
