extends Message

class_name EnterLobby

const PROPERTIES = ["global_id", "ig_player_id", "nickname", "ig_peer_id", "color", "second_color"]

var color: Color
var second_color: Color
var ig_peer_id: int
var nickname: String
var global_id: String
var ig_player_id: int

func _init (a: Array = []):
	if not a.empty():
		init_from_array(a)

func get_properties() -> Array:
	return PROPERTIES + .get_properties()
