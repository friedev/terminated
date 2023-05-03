extends Node

const CONFIG_PATH := "user://options.cfg"
const OPTIONS_SECTION := "options"
const OPTIONS_GROUP := &"options"


func load_config():
	var config := ConfigFile.new()
	config.load(self.CONFIG_PATH)
	for option_node in self.get_tree().get_nodes_in_group(self.OPTIONS_GROUP):
		var option := option_node as Option
		if config.has_section_key(self.OPTIONS_SECTION, option.key):
			option.set_option(
				config.get_value(self.OPTIONS_SECTION, option.key), false
			)


func save_config():
	var config := ConfigFile.new()
	for option_node in self.get_tree().get_nodes_in_group(self.OPTIONS_GROUP):
		var option := option_node as Option
		config.set_value(self.OPTIONS_SECTION, option.key, option.get_option())
	config.save(self.CONFIG_PATH)


func _ready() -> void:
	self.load_config()


func _on_option_changed(value) -> void:
	self.save_config()
