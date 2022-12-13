extends Node

signal player_added(ap)
signal player_removed(ap)

class AdaptedPlayer:
	var nw_player: NetworkPlayer
	var color: Color
	var index: int
	var this_machine: bool
	var peer_id: int
	var nickname: String
	
	func dump():
		print("#%d=%s ('%s')" % [index, peer_id, nickname])
	
var connected: Array = []   # of AdaptedPlayer

var peers: Dictionary = {}  # of peer_id -> [AdaptedPlayer]

func dump():
	print("Dump of players connected:")
	for p in connected:
		p.dump()


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
	else:
		peers[peer_id].append(ap)
	
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
	emit_signal("player_added", ap)

# Remove a player.
# The following player will move one position up.
func remove(ap: AdaptedPlayer):
	print("Before remove %s:" % ap)
	dump()
	var index = ap.index
	var peer_id = ap.nw_player.peer_id
	# Remove from peers
	if not peers[peer_id].erase(ap):
		printerr("Internal error erasing player %s" % ap)
	# Remove from connected and re-index the rest of the connected players		
	connected.remove(index)
	for i in range(index, len(connected)):
		connected[i].index -= 1
	print("After remove:")
	dump()
	emit_signal("player_removed", ap)
	
func remove_peer(peer_id):
	print("Removing peer %s" % peer_id)
	if peers.has(peer_id):
		for ap in peers[peer_id]:
			remove(ap)
		peers.erase(peer_id)
	else:
		printerr("Peer was not connected: %s" % peer_id)
