extends Resource

class_name PlayerProfile

export var global_id: String = ""
export var nickname: String = "unknown"

export var fav_color1: Color = Color(1,0,0,1)
export var fav_color2: Color = Color(0,0,1,1)

func save_local():
	var filename = "user://pp_%s.tres" % global_id
	var result = ResourceSaver.save(filename, self)
	if result != OK:
		printerr("Failed to save player %s to %s, errorcode %d" % [nickname, filename, result])

static func load_local(filename):
	var player_profile = ResourceLoader.load(filename, "", true)
	if player_profile == null:
		push_error("Failed to load player from resource %s" % filename)
		return null
	else:
		print("Loaded player %s" % player_profile.nickname)
		return player_profile

static func load_all_local():
	var player_profiles = []
	var dir = Directory.new()
	dir.open("user://")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		print("file=", file)
		if file == "":
			break
		elif file.begins_with("pp_") and file.ends_with(".tres"):
			var player_profile = load_local("user://%s" % file)
			player_profiles.append(player_profile)
	dir.list_dir_end()
	return player_profiles
