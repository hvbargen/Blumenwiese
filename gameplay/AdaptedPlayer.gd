extends Resource

class_name AdaptedPlayer

export var color: Color
export var second_color: Color
export var ig_player_id: int
export var ig_peer_id: int
export var nickname: String
var global_id: String
var controller: InputController

var node_paths = []


func _init(a_player_profile: PlayerProfile, a_ig_peer_id: int, a_controller: InputController) -> void:
	._init()
	self.ig_peer_id = a_ig_peer_id
	self.nickname = a_player_profile.nickname
	self.controller = a_controller
	self.color = a_player_profile.fav_color1
	self.second_color = a_player_profile.fav_color2
	self.global_id = a_player_profile.global_id
	#controller.ig_player_id = Lobby.get_ig_player_id(ig_peer_id, controller.controller_id)
	controller.set_ig_peer_id(ig_peer_id)


func dump() -> void:
	print("Player %s (controlled by '%s' from peer %s) = %s" % [ig_player_id, nickname, ig_peer_id, global_id])


func change_colors(first: Color, second: Color) -> void:
	self.color = first
	self.second_color = second
	GameEvents.emit_signal("color_changed", global_id, first, second)


func register_node_path(np: NodePath):
	if not np in node_paths:
		 node_paths.append(np)


func unregister_node_path(np: NodePath):
	node_paths.erase(np)
	
	
func remove_silently(root: Node):
	for np in node_paths:
		print("Removing node " + np)
		root.get_node(np).queue_free()
