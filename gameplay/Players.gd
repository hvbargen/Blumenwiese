extends Node

signal player_added(ap)
signal player_removed(ap)

var connected: Dictionary = {} # of global_id -> AdaptedPlayer

var peers: Dictionary = {}  # of peer_id -> [global_id]

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
