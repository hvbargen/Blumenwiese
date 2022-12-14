extends Node

signal player_added(ap)
signal player_removed(ap)

var connected: Dictionary = {} # of global_id -> AdaptedPlayer

var peers: Dictionary = {}  # of peer_id -> [global_id]

var max_in_game_uid := 0 # The actual values start at 1

var in_game_uids := {}


# Find an unused in_game_uid and assign it to the global_id
func _assign_in_game_uid(global_id: String) -> String:
	if in_game_uids.has(global_id):
		print("Reusing in_game_uid %s for global_id %s" % [in_game_uids[global_id], global_id])
		return in_game_uids[global_id]
	max_in_game_uid += 1
	var uid := "%s" % max_in_game_uid
	while in_game_uids.values().has(uid):
		max_in_game_uid += 1
		uid = "%s" % max_in_game_uid
	in_game_uids[global_id] = uid
	print("Assigned in_game_uid %s for global_id %s" % [uid, global_id])
	return uid


remote func assign_in_game_uid(global_id: String) -> void:
	var uid = _assign_in_game_uid(global_id)
	rpc_id(get_tree().get_rpc_sender_id(), "on_server_assigned_in_game_uid", global_id, uid)


remote func on_server_assigned_in_game_uid(global_id: String, uid: String) -> void:
	print("Server assigned in_game_uid %s to global_id %s" % [uid, global_id])
	in_game_uids[global_id] = uid
	connected[global_id].in_game_uid = uid


func dump() -> void:
	print("Dump of players connected:")
	for p in connected.values():
		p.dump()


func find(global_id: String) -> AdaptedPlayer:
	return connected[global_id]


func add(ap: AdaptedPlayer) -> void:
	dump()
	if not (ap.peer_id in peers):
		peers[ap.peer_id] = [ap.global_id]
	else:
		peers[ap.peer_id].append(ap.global_id)

	# Assign a unique id
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			# We are the server
			ap.in_game_uid = _assign_in_game_uid(ap.global_id)
			print("TODO: Notify the other peers about assigned in_game_uid")
		else:
			# We are a client
			# Ask the server to assign an id
			rpc_id(1, "assign_in_game_uid", ap.global_id)
	else:
		# local game
		ap.in_game_uid = _assign_in_game_uid(ap.global_id)
	
	# TODO Try to choose a unique color
	var existing_colors: Array = []
	for apc in connected.values():
		existing_colors.append(apc.color)
	if not (ap.color in existing_colors):
		pass
	elif not (ap.second_color in existing_colors):
		ap.change_colors(ap.second_color, ap.color)
	else:
		var color1 = Color.from_hsv(randf(), rand_range(0.8, 1), rand_range(0.8, 1), 1)
		var color2 = ap.color 
		ap.change_colors(color1, color2)
		print("Had to choose a random color for %s" % ap.nickname)
	connected[ap.global_id] = ap
	print("After add:")
	dump()
	emit_signal("player_added", ap)


# Remove a player.
func remove(global_id: String) -> void:
	print("Before remove %s:" % global_id)
	dump()
	var ap := find(global_id)
	if not (connected.erase(global_id)):
		printerr("Trying to remove player who is not connected: ", global_id)
		return
	var peer_id := ap.peer_id
	# Remove from peers
	peers[peer_id].erase(global_id)
	print("After remove:")
	dump()
	emit_signal("player_removed", ap)


func remove_peer(peer_id) -> void:
	print("Removing peer %s" % peer_id)
	if peers.has(peer_id):
		for ap in peers[peer_id]:
			remove(ap)
# warning-ignore:return_value_discarded
		peers.erase(peer_id)
	else:
		printerr("Peer was not connected: %s" % peer_id)
