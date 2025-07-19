extends Label


func _ready() -> void:
	self.hide()


func update_timer() -> void:
	self.text = Utility.format_msec(Time.get_ticks_msec() - Globals.start_ticks)


func _process(_delta: float) -> void:
	# Stop timer after player dies
	if Player.instance.alive:
		self.update_timer()


func _on_main_game_started() -> void:
	self.show()


func _on_player_died() -> void:
	self.update_timer()
