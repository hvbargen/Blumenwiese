extends Resource

class_name AdaptedPlayer

export var color: Color
export var second_color: Color
export var in_game_uid: String setget set_in_game_uid
export var peer_id: int
export var nickname: String
var nw_player: NetworkPlayer
var controller: InputController


func _init(a_nw_player: NetworkPlayer, a_peer_id: int, a_controller: InputController) -> void:
	._init()
	self.nw_player = a_nw_player
	self.peer_id = a_peer_id
	self.controller = a_controller
	in_game_uid = controller.in_game_uid


func dump() -> void:
	print("Player %s (controlled by '%s' from peer %s) = %s" % [in_game_uid, nickname, peer_id, nw_player.global_id])


func set_in_game_uid(new_in_game_uid: String) -> void:
	print("Setting in_game_uid for %s to %s" % [nickname, new_in_game_uid])
	in_game_uid = new_in_game_uid
	controller.set_in_game_uid (in_game_uid)
