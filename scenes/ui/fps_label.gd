extends Label

func _process(_delta: float) -> void:
	self.visible = Options.options["show_fps"]
	text = "FPS: %d" % Engine.get_frames_per_second()