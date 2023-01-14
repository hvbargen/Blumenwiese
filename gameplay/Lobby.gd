extends Node

# class_name Lobby

"""
The Lobby singleton manages all peers connected to a game
and all players connected to a game.

A player profile can be identified by its global_id, which is actually
globally unique (and will never change).

A network peer is can be identified by its network_unique_id,
sometimes called peer_id (the naming is not quite consistent in Godot).

However, the `global_id` string for a player profile as well as the
`peer_id` int for a peer, are quite long, not very handy.

We want to avoid sending these long data items over the network
and to print them in debug/log messages.

Thus we introduce shorter IDs which are unique only for the duration
of a server session. To separate them from the longer IDs,
we will call these "in-game IDs" and will use a prefix "ig_" for them:

`ig_player_id` means an in-game player ID; this is a number which
uniquely identifies a player (profile) profile during a game.

`ig_peer_id` means an in-game peer ID; this is a number which
uniquely identifies a peer during a game.

Note:
When a machine changes its network role, eg when it connects
to a network server, then it will change its `ig_peer_id`.

Furthermore, the server decides about the "cloth colors" of players
in order to make the avatars distinguishable.

Because the `ig_peer_id` is also used as part of the name of nodes
in the tree, these nodes have to be renamed then.

These nodes should therefore connect to the `ig_peer_id_changed` signal
and rename themselves accordingly.

The `ig_player_id` is computed from the `ig_peer_id` and
the (machine-local) `controller_id` with the following formula:
	
	ig_player_id = ig_peer_id * 10 + controller_id,

which allows up to 10 controllers on a single machine.

Thus when the ig_peer_id changes, the ig_player_ids
for the players on this peer have to change as well.
"""

var connected: Dictionary = {} # of global_id -> AdaptedPlayer

var _peer_id_to_ig_peer_id := {} # of peer_id -> ig_peer_id
var _ig_peer_id_to_peer_id := {} # of ig_peer_id -> peer_id

var _max_ig_peer_id := 0 # The actual values start at 1 for a network game

var _wait_for_peer_id := false

var own_peer_id := 1
var own_ig_peer_id := 1

enum NetworkState { LOCAL, SERVER, UNCONNECTED_CLIENT, CLIENT}

var network_state = NetworkState.LOCAL


func _init():
	._init()
	network_state = NetworkState.LOCAL
	own_ig_peer_id = 1
	_init_peer_ids_for_local_game()

	
func _init_peer_ids_for_local_game():
	# Init peer_id mappings for local game
	_peer_id_to_ig_peer_id.clear()
	_ig_peer_id_to_peer_id.clear()
	_peer_id_to_ig_peer_id[1] = 1
	_ig_peer_id_to_peer_id[1] = 1


func _init_peer_ids_for_server_game():
	_init_peer_ids_for_local_game()
	

func _ready():
	
	var mp := get_tree().multiplayer
	# warning-ignore:return_value_discarded
	mp.connect("server_disconnected", self, "on_server_disconnected")
	# warning-ignore:return_value_discarded
	mp.connect("connected_to_server", self, "on_connected_to_server")
	# warning-ignore:return_value_discarded
	mp.connect("connection_failed", self, "on_connection_failed")
	# warning-ignore:return_value_discarded
	mp.connect("network_peer_connected", self, "on_network_peer_connected")
	# warning-ignore:return_value_discarded
	mp.connect("network_peer_disconnected", self, "on_network_peer_disconnected")


func kick_remote_players():
	print("TODO remove all remote players")
	

func init_local():
	print("Initializing local game")
	leave_network()
	network_state = NetworkState.LOCAL
	var old_ig_peer_id := own_ig_peer_id
	own_peer_id = 1
	own_ig_peer_id = 1
	_init_peer_ids_for_local_game()
	if old_ig_peer_id != own_ig_peer_id:
		GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)


func init_server(host: String, port: int, max_players: int):
	assert(network_state == NetworkState.LOCAL)
	kick_remote_players()
	network_state = NetworkState.SERVER
	print("Initializing Server ", host, ":", port, " -- Note that the host is actually ignored!")
	var old_ig_peer_id := own_ig_peer_id
	var peer = NetworkedMultiplayerENet.new()
	peer.set_bind_ip(host)
	var error = peer.create_server(port, max_players)
	if error == OK:
		get_tree().network_peer = peer
		own_peer_id = get_tree().get_network_unique_id()
		assert(own_peer_id == 1)
		own_ig_peer_id = 1
		_init_peer_ids_for_server_game()
		if old_ig_peer_id != own_ig_peer_id:
			GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)
	else:
		network_state = NetworkState.LOCAL
		own_peer_id = 1
		own_ig_peer_id = 1
		_init_peer_ids_for_local_game()
		if old_ig_peer_id != own_ig_peer_id:
			GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)
	return error	


func init_client(server_host: String, server_port: int):
	print("Initializing Client, connecting to ", server_host, ":", server_port)
	kick_remote_players()
	network_state = NetworkState.UNCONNECTED_CLIENT
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_host, server_port)
	get_tree().network_peer = peer
	own_peer_id = get_tree().get_network_unique_id()
	var old_ig_peer_id = own_ig_peer_id
	own_ig_peer_id = 0
	# Adjust the two peer_id dicts
	_peer_id_to_ig_peer_id.clear()
	_ig_peer_id_to_peer_id.clear()
	_peer_id_to_ig_peer_id[own_peer_id] = own_ig_peer_id
	_ig_peer_id_to_peer_id[own_ig_peer_id] = own_peer_id
	GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)


func on_server_disconnected():
	print("Disconnected from server")
	kick_remote_players()
	network_state = NetworkState.LOCAL
	get_tree().network_peer = null
	own_peer_id = 1
	var old_ig_peer_id = own_ig_peer_id
	own_ig_peer_id = 1
	_init_peer_ids_for_local_game()
	GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)
	
	
func on_connected_to_server():
	# Called on client when connected to the server.
	# Wir müssen darauf warten, dass uns der Server eine ig_peer_id zuweist.
	print("We have to wait for the server to send us an ig_peer_id")
	_wait_for_peer_id = true
	

func _server_assigned_ig_peer_id(new_ig_peer_id: int) -> void:
	print("The server assigned ig_peer_id %s to us." % new_ig_peer_id)
	# We assume that our previous ig_peer_id was 1,
	# because we were not connected before, thus the settings were
	# for a local game.
	assert(_wait_for_peer_id)
	assert(network_state == NetworkState.UNCONNECTED_CLIENT)
	_wait_for_peer_id = false
	var old_ig_peer_id := own_ig_peer_id
	var peer_id := get_tree().get_network_unique_id()
	_peer_id_to_ig_peer_id.clear()
	_ig_peer_id_to_peer_id.clear()
	_peer_id_to_ig_peer_id[peer_id] = new_ig_peer_id
	_ig_peer_id_to_peer_id[new_ig_peer_id] = peer_id
	network_state = NetworkState.CLIENT
	own_ig_peer_id = new_ig_peer_id
	GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)
		
	# We should now tell the server about our players
	print("TODO We should now tell the server and the other peers about our players")


func on_connection_failed():
	# Called on clients if connection failed
	print("Connection to server failed")
	kick_remote_players()
	get_tree().network_peer = null
	network_state = NetworkState.LOCAL
	var old_ig_peer_id = own_ig_peer_id
	own_peer_id = 1
	own_ig_peer_id = 1
	_init_peer_ids_for_local_game()
	_wait_for_peer_id = false
	GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)


func leave_network():
	if network_state != NetworkState.LOCAL:
		print("TODO: Tell the others that we're leaving!")
		rpc("bye")
		kick_remote_players()
		get_tree().network_peer = null
		network_state = NetworkState.LOCAL
		var old_ig_peer_id = own_ig_peer_id
		own_peer_id = 1
		own_ig_peer_id = 1
		_init_peer_ids_for_local_game()
		_wait_for_peer_id = false
		GameEvents.emit_signal("ig_peer_id_changed", old_ig_peer_id, own_ig_peer_id)

	
func on_network_peer_connected(peer_id: int):
	# This is called on all peers including the server
	if get_tree().is_network_server():
		var ig_peer_id := _assign_ig_peer_id(peer_id)
		print("Peer %s connected, assigned ig_peer_id %s." % [peer_id, ig_peer_id])
		rpc("recv_peer_registered", peer_id, ig_peer_id)
	else:
		print("Peer %s connected. Ignoring this" % peer_id)
		

remote func recv_peer_registered(peer_id: int, ig_peer_id: int):
	print("Received msg from master: peer_id %s => ig_peer_id %s." % [peer_id, ig_peer_id])
	if peer_id == own_peer_id:
		_server_assigned_ig_peer_id(ig_peer_id)
	else:
		# Den Zusammenhang zur Kenntnis nehmen
		var existing = _peer_id_to_ig_peer_id.get(peer_id)
		if existing is int:
			_peer_id_to_ig_peer_id.erase(peer_id)
			_ig_peer_id_to_peer_id.erase(existing)
		_peer_id_to_ig_peer_id[peer_id] = ig_peer_id
		_ig_peer_id_to_peer_id[ig_peer_id] = peer_id

	
func _assign_ig_peer_id(peer_id: int) -> int:
	var ig_peer_id = _peer_id_to_ig_peer_id.get(peer_id)
	if ig_peer_id is int:
		print("Reusing ig_peer_id %s for peer_id %s" % [ig_peer_id, peer_id])
		return ig_peer_id
	else:
		_max_ig_peer_id += 1
		ig_peer_id = _max_ig_peer_id
		_peer_id_to_ig_peer_id[peer_id] = ig_peer_id
		_ig_peer_id_to_peer_id[ig_peer_id] = peer_id
		print("Assigned ig_peer_id %s to peer_id %s" % [ig_peer_id, peer_id])
		return ig_peer_id


# Find an unused ig_player_id and assign it to the global_id
func get_ig_player_id(ig_peer_id: int, controller_id: int) -> int:
	return ig_peer_id * 10 + controller_id


func dump() -> void:
	print("Dump of players connected:")
	for p in connected.values():
		p.dump()


func find(global_id: String) -> AdaptedPlayer:
	return connected[global_id]
	

func enter(ap: AdaptedPlayer) -> void:
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
	GameEvents.emit_signal("player_entered_lobby", ap)


# Remove a player.
func leave(global_id: String) -> void:
	print("Before remove %s:" % global_id)
	dump()
	var ap := find(global_id)
	if not (connected.erase(global_id)):
		printerr("Trying to remove player who is not connected: ", global_id)
		return
	print("After remove:")
	dump()
	ap.remove_silently(get_tree().get_root())
	GameEvents.emit_signal("player_left_lobby", ap)


func remove_peer(peer_id) -> void:
	print("Removing peer %s" % peer_id)
	var ig_peer_id = _peer_id_to_ig_peer_id[peer_id]
	var leaving := []
	for global_id in connected.keys():
		var ap := connected[global_id] as AdaptedPlayer
		if ap.ig_peer_id == ig_peer_id:
			leaving.append(ap)
	for ap in leaving:
		leave(ap)


func get_own_ig_peer_id() -> int:
	return own_ig_peer_id


func is_local(ap: AdaptedPlayer) -> bool:
	return ap.ig_peer_id == own_ig_peer_id


func get_local_players() -> Array:
	# How many players are local players?
	var local_players = []
	print("Local players ")
	for ap in connected.values():
		if is_local(ap):
			local_players.append(ap)
			print("    ", ap.nickname)
	return local_players


func start_game():
	print("Starting Game...")
	# print("Disabling new network connections...")
	if Lobby.network_state != Lobby.NetworkState.LOCAL:
		get_tree().set_refuse_new_network_connections(false)
	
