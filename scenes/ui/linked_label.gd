# https://godotengine.org/qa/46978/how-do-i-open-richtextlabel-bbcode-links-in-an-html5-export?show=74333#a74333
extends RichTextLabel


func _ready() -> void:
	self.meta_clicked.connect(self._on_meta_clicked)


func _on_meta_clicked(meta: Variant) -> void:
	if not meta is String:
		assert(false)
	else:
		OS.shell_open(meta as String)
