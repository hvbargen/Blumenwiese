extends Resource

class_name NetworkPlayer

export var global_id: String = ""
export var nickname: String = "unknown"

export var fav_color1: Color = Color(1,0,0,1)
export var fav_color2: Color = Color(0,0,1,1)

func save_local():
	var filename = "user://nwp_%s.tres" % global_id
	var result = ResourceSaver.save(filename, self)
	if result != OK:
		printerr("Failed to save player %s to %s, errorcode %d" % [nickname, filename, result])

static func load_local(filename):
	var nw_player = ResourceLoader.load(filename, "", true)
	if nw_player == null:
		push_error("Failed to load player from resource %s" % filename)
		return null
	else:
		print("Loaded player %s" % nw_player.nickname)
		return nw_player

static func load_all_local():
	var nw_players = []
	var dir = Directory.new()
	dir.open("user://")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		print("file=", file)
		if file == "":
			break
		elif file.begins_with("nwp_") and file.ends_with(".tres"):
			var nw_player = load_local("user://%s" % file)
			nw_players.append(nw_player)
	dir.list_dir_end()
	return nw_players
