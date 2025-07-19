class_name HighScoreLabel extends Label

const CONFIG_PATH := "user://scores.cfg"
const SECTION := "scores"
const KEY := "high_score"

var config := ConfigFile.new()
var high_score: int:
	set(value):
		high_score = value
		self.update_text()
		self.config.set_value(self.SECTION, self.KEY, self.high_score)
		self.config.save(self.CONFIG_PATH)


func _ready() -> void:
	if self.config.load(self.CONFIG_PATH) == OK:
		self.high_score = self.config.get_value(self.SECTION, self.KEY)
	self.hide()


func update_text() -> void:
	self.visible = self.high_score > 0
	self.modulate = Color.GRAY
	self.text = "Best: %s" % Utility.format_msec(self.high_score)


func _on_player_died() -> void:
	var milliseconds := Time.get_ticks_msec() - Globals.start_ticks
	var new_best := milliseconds > self.high_score
	self.high_score = maxi(self.high_score, milliseconds)
	if new_best:
		self.show()
		self.modulate = Color.YELLOW
		self.text = "New Best"


func _on_main_game_started() -> void:
	self.hide()