extends Node

signal player_added
signal player_removed

class AdaptedPlayer:
	var nw_player: NetworkPlayer
	var color: Color
	var index: int
	var this_machine: bool
	var peer_id: int
	var nickname: String
	
	func dump():
		print("#%d=%s ('%s')", index, peer_id, nickname)
	
var connected: Array = []   # of AdaptedPlayer

var peers: Dictionary = {}  # of peer_id -> AdaptedPlayer

func dump():
	print("Dump of players connected:")
	for p in connected:
		print(p.dump())


func add(nw_player: NetworkPlayer, peer_id):
	print("Before add %s:" % nw_player)
	dump()
	var ap = AdaptedPlayer.new()
	ap.nw_player = nw_player
	ap.peer_id = peer_id
	ap.nickname = nw_player.nickname
	if get_tree().get_network_unique_id() == peer_id:
		ap.this_machine = true
	else:
		ap.this_machine = false
	ap.index = len(connected)
	if not (peer_id in peers):
		peers[peer_id] = [ap]
	
	# TODO Try to choose a unique color
	var existing_colors: Array = []
	for apc in connected:
		existing_colors.append(apc.color)
	if not (ap.nw_player.fav_color1 in existing_colors):
		ap.color = ap.nw_player.fav_color1
	elif not (ap.nw_player.fav_color2 in existing_colors):
		ap.color = ap.nw_player.fav_color2
	else:
		ap.color = Color.from_hsv(randf(), rand_range(0.8, 1), rand_range(0.8, 1), 1)
		print("Must choose a random color for %s" % ap.nickname)
	connected.append(ap)
	print("After add:")
	dump()
	emit_signal("player_added")

# Remove a player.
# The following player will move one position up.
func remove(nw_player):
	print("Before remove %s:" % nw_player)
	dump()
	var index = -1
	var peer_id = -1
	if nw_player is AdaptedPlayer:
		index = nw_player.index
	elif nw_player is NetworkPlayer:
		peer_id = nw_player.peer_id
	elif nw_player is int:
		index = nw_player
	if index == -1 and peer_id != -1:
		index = peers[peer_id].index
	if index >= 0 and index < len(connected):
		var to_remove = connected[index]
		if not peers.erase(to_remove.peer_id):
			printerr("Internal error erasing player %s" % nw_player)
		connected.remove(index)
		for i in range(index, len(connected)):
			connected[i].index -= 1
	else:
		printerr("Cannot find player %s" % nw_player)
	print("After remove:")
	dump()
	emit_signal("player_removed")
	
func remove_peer(peer_id):
	print("Removing peer %s" % peer_id)
	if peers.has(peer_id):
		for ap in peers[peer_id]:
			remove(ap)
		peers.erase(peer_id)
	else:
		printerr("Peer was not connected: %s" % peer_id)
