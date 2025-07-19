class_name HighScoreLabel extends Label

const CONFIG_PATH := "user://scores.cfg"
const SECTION := "scores"
const KEY := "high_score"

var config := ConfigFile.new()
var high_score: int:
	set(value):
		high_score = value
		update_text()
		config.set_value(SECTION, KEY, high_score)
		config.save(CONFIG_PATH)


func _ready() -> void:
	if config.load(CONFIG_PATH) == OK:
		high_score = config.get_value(SECTION, KEY)
	hide()


func update_text() -> void:
	visible = high_score > 0
	modulate = Color.GRAY
	text = "Best: %s" % Utility.format_msec(high_score)


func _on_player_died() -> void:
	var milliseconds := Time.get_ticks_msec() - Globals.start_ticks
	var new_best := milliseconds > high_score
	high_score = maxi(high_score, milliseconds)
	if new_best:
		show()
		modulate = Color.YELLOW
		text = "New Best"


func _on_main_game_started() -> void:
	hide()