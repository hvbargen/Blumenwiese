extends Node

signal player_added(ap)
signal player_removed(ap)

var connected: Dictionary = {} # of global_id -> AdaptedPlayer

var peers: Dictionary = {}  # of peer_id -> [global_id]

var max_in_game_uid := 0

var in_game_uids := {}

# Find an unused in_game_uid and assign it to the global_id
func _assign_in_game_uid(global_id: String) -> String:
	if in_game_uids.has(global_id):
		# Reuse it
		return in_game_uids[global_id]
	var uid = "%s" % max_in_game_uid
	max_in_game_uid += 1
	while in_game_uids.has(uid):
		uid = "%s" % max_in_game_uid
		max_in_game_uid += 1
	return uid

remote func assign_in_game_uid(global_id: String):
	var uid = _assign_in_game_uid(global_id)
	rpc_id(get_tree().get_rpc_sender_id(), "on_server_assigned_in_game_uid", global_id, uid)

remote func on_server_assigned_in_game_uid(global_id: String, uid: String):
	in_game_uids[global_id] = uid
	connected[global_id].in_game_uid = uid
	
func dump():
	print("Dump of players connected:")
	for p in connected.values():
		p.dump()

func find(global_id: String) -> AdaptedPlayer:
	return connected[global_id]

func add(nw_player, peer_id: int, controller: InputController):
	print("Before add %s:" % nw_player)
	dump()
	var global_id = nw_player.global_id
	var ap = AdaptedPlayer.new(nw_player, peer_id, controller)
	ap.nw_player = nw_player
	ap.peer_id = peer_id
	ap.nickname = nw_player.nickname
	if not (peer_id in peers):
		peers[peer_id] = [global_id]
	else:
		peers[peer_id].append(global_id)

	# Assign a unique id
	if get_tree().has_network_peer():
		if get_tree().get_network_unique_id() == 1:
			# We are the server
			ap.in_game_uid = _assign_in_game_uid(global_id)
			# TODO: Notify the other peers
		else:
			# We are a client
			# Ask the server to assign an id
			rpc_id(1, "assign_in_game_uid", global_id)
	else:
		# local game
		ap.in_game_uid = _assign_in_game_uid(global_id)
	
	# TODO Try to choose a unique color
	var existing_colors: Array = []
	for apc in connected.values():
		existing_colors.append(apc.color)
	if not (ap.nw_player.fav_color1 in existing_colors):
		ap.color = ap.nw_player.fav_color1
		ap.second_color = ap.nw_player.fav_color2
	elif not (ap.nw_player.fav_color2 in existing_colors):
		ap.color = ap.nw_player.fav_color2
		ap.second_color = ap.nw_player.fav_color1
	else:
		ap.color = Color.from_hsv(randf(), rand_range(0.8, 1), rand_range(0.8, 1), 1)
		print("Must choose a random color for %s" % ap.nickname)
	connected[global_id] = ap
	print("After add:")
	dump()
	emit_signal("player_added", ap)
	return ap

# Remove a player.
func remove(global_id: String):
	print("Before remove %s:" % global_id)
	dump()
	var ap = find(global_id)
	if not (connected.erase(global_id)):
		printerr("Trying to remove player who is not connected: ", global_id)
		return
	var peer_id = ap.peer_id
	# Remove from peers
	peers[peer_id].erase(global_id)
	print("After remove:")
	dump()
	emit_signal("player_removed", ap)
	
func remove_peer(peer_id):
	print("Removing peer %s" % peer_id)
	if peers.has(peer_id):
		for ap in peers[peer_id]:
			remove(ap)
# warning-ignore:return_value_discarded
		peers.erase(peer_id)
	else:
		printerr("Peer was not connected: %s" % peer_id)
