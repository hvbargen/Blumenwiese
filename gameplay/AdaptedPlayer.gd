extends Resource

class_name AdaptedPlayer

export var color: Color
export var second_color: Color
export var local_id: String
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
		local_id = ""
	else:
		local_id = controller.local_id

func dump():
	print("%s (controlled by '%s' from peer %s) = %s" % [local_id, nickname, peer_id, nw_player.global_id])
