extends Label


func _ready() -> void:
	self.hide()


func _process(_delta: float) -> void:
	# Stop timer after player dies
	if Player.instance.alive:
		var milliseconds := Time.get_ticks_msec() - Globals.start_ticks
		@warning_ignore("integer_division")
		var seconds := milliseconds / 1000
		@warning_ignore("integer_division")
		var minutes := seconds / 60
		milliseconds %= 1000
		seconds %= 60
		self.text = "%02d:%02d.%03d" % [minutes, seconds, milliseconds]


func _on_main_game_started() -> void:
	self.show()