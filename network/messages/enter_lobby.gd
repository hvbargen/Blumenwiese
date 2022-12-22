extends Message

class_name EnterLobby

const PROPERTIES = ["global_id", "nickname", "peer_id", "color", "second_color"]

var color: Color
var second_color: Color
var peer_id: int
var nickname: String
var global_id: String

func _init (a: Array = []):
	if not a.empty():
		init_from_array(a)

func get_properties() -> Array:
	return PROPERTIES + .get_properties()
