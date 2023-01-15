extends Node

#class_name LogConf

var levels: Dictionary

export var url := "user://log_conf.json"

enum Level { DEBUG, INFO, WARN, ERROR, OFF }

func _init():
	print("LogConf init.")
	var level_config: Dictionary
	var file := File.new()
	var error = file.open(url, File.READ)
	if error == OK:
		var json = file.get_as_text()
		print("JSON=", json)
		file.close()
		level_config = JSON.parse(json).result as Dictionary
	if not level_config.empty():
		print("Read logging configuration from file ", url)
	else:
		print("Logging configuration not found or invalid, creating a new one in ", url)
		level_config = { "default": "INFO" }
		file = File.new()
		if file.open(url, File.WRITE) == OK:
			file.store_string(to_json(level_config))
			file.close()
	
	if not (level_config.has("default")):
		level_config["default"] = "INFO"
	levels = {}
	for key in level_config.keys():
		var level_name := level_config[key] as String
		var level = Level.get(level_name.to_upper())
		levels[key] = level
		
	print("levels=", levels)

func get_level(name: String) -> int:
	if levels.has(name):
		return levels[name]
	else:
		return levels["default"]
