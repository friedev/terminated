extends Label

func _process(_delta: float) -> void:
	self.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fps"):
		self.visible = not self.visible