extends Resource

class_name AdaptedPlayer

export var color: Color
export var second_color: Color
export var in_game_uid: String setget set_in_game_uid
export var peer_id: int
export var nickname: String
var global_id: String
var controller: InputController


func _init(a_player_profile: PlayerProfile, a_peer_id: int, a_controller: InputController) -> void:
	._init()
	self.peer_id = a_peer_id
	self.nickname = a_player_profile.nickname
	self.controller = a_controller
	self.color = a_player_profile.fav_color1
	self.second_color = a_player_profile.fav_color2
	self.global_id = a_player_profile.global_id
	in_game_uid = controller.in_game_uid


func dump() -> void:
	print("Player %s (controlled by '%s' from peer %s) = %s" % [in_game_uid, nickname, peer_id, global_id])


func set_in_game_uid(new_in_game_uid: String) -> void:
	print("Setting in_game_uid for %s to %s" % [nickname, new_in_game_uid])
	in_game_uid = new_in_game_uid
	controller.set_in_game_uid (in_game_uid)


func change_colors(first: Color, second: Color) -> void:
	self.color = first
	self.second_color = second
	GameEvents.emit_signal("color_changed", global_id, first, second)
