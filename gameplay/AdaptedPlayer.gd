extends Resource

class_name AdaptedPlayer

export var color: Color
export var second_color: Color
export var in_game_uid: String setget set_in_game_uid
export var peer_id: int
export var nickname: String
var nw_player: NetworkPlayer
var controller: InputController

func _init(a_nw_player, a_peer_id: int, a_controller: InputController) -> void:
	._init()
	self.nw_player = a_nw_player as NetworkPlayer
	self.peer_id = a_peer_id
	self.controller = a_controller
	if controller.type == InputController.REMOTE:
		in_game_uid = ""
	else:
		in_game_uid = controller.in_game_uid

func dump():
	print("%s (controlled by '%s' from peer %s) = %s" % [in_game_uid, nickname, peer_id, nw_player.global_id])

func set_in_game_uid(new_in_game_uid: String):
	in_game_uid = new_in_game_uid
	controller.in_game_uid = in_game_uid
