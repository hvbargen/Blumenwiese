extends Resource

class_name AdaptedPlayer

var nw_player: NetworkPlayer
var color: Color
var index: int
var peer_id: int
var nickname: String
var controller: InputController

func _init(a_nw_player: NetworkPlayer, a_peer_id: int, a_controller: InputController) -> void:
	._init()
	self.nw_player = a_nw_player
	self.peer_id = a_peer_id
	self.controller = a_controller

func dump():
	print("#%d=%s (controlled by '%s' using %s)" % [index, peer_id, nickname, controller.device_name])
