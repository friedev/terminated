class_name Utility


static func format_msec(milliseconds: int) -> String:
	@warning_ignore("integer_division")
	var seconds := milliseconds / 1000
	@warning_ignore("integer_division")
	var minutes := seconds / 60
	milliseconds %= 1000
	seconds %= 60
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
