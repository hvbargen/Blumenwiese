extends Control


const MAX_PLAYERS := 4

const Logger = preload("res://util/Logger.gd")
var logger: Logger

var server_host := "192.168.178.56"
var server_port : int = 9000

var local_profiles: Array # of NetworkPlayer

var current_input_controller: InputController = InputController.new()

var podest_scene := preload("res://scenes/podest/Podest.tscn")

var players_not_ready: Array = [] # of global_id

var podest_vpcs: Dictionary = {} # of global_id -> ViewPortContainer.name

export onready var vpc_template = $VBoxContainer/ConnectedPlayers/TemplateViewPortContainer as ViewportContainer
export onready var player_node_template = $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles/DummyPlayer as Button

func _init():
	._init()
	logger = Logger.new("NetStartMenu")
	logger.level = Logger.Level.DEBUG
	logger.name += (get_instance_id() as String)

# Called when the node enters the scene tree for the first time.
func _ready():
	
	player_node_template.hide()
	vpc_template.hide()
	var mp = get_tree().multiplayer
	$VBoxContainer/Network/TxtHost.text = server_host
	$VBoxContainer/Network/TxtPort.text = server_port as String

	mp.connect("server_disconnected", self, "on_server_disconnected")
	mp.connect("connected_to_server", self, "on_connected_to_server")
	mp.connect("connection_failed", self, "on_connection_failed")
	mp.connect("network_peer_connected", self, "on_network_peer_connected")
	mp.connect("network_peer_disconnected", self, "on_network_peer_disconnected")
	load_local_profiles()
	$VBoxContainer/Network/BtnLocal.call_deferred("grab_focus")

func load_local_profiles() -> void:
	local_profiles = NetworkPlayer.load_all_local()
	show_local_profiles()

func show_local_profiles() -> void:
	var container := $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles
	for child in container.get_children():
		if child.name.begins_with("Icon"):
			child.free()
	for nw_player in local_profiles:
		show_local_profile(nw_player)
		
func show_local_profile(nw_player: NetworkPlayer):
	var container := $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles
	print("show ", nw_player.nickname)
	var pn: Button = player_node_template.duplicate()
	var index := container.get_child_count() - 1
	container.add_child(pn)
	container.move_child(pn, index)
	pn.name = "Icon#%d" % index
	update_local_profile_button(pn, nw_player)
	
func update_local_profile_button(pn: Button, nw_player):
	pn.global_id = nw_player.global_id
	pn.get_node("Col1").color = nw_player.fav_color1
	pn.get_node("Col2").color = nw_player.fav_color2
	pn.get_node("Nickname").text = nw_player.nickname
	pn.visible = true

func _input(event: InputEvent):
	if event is InputEventMouse:
		return
	if event is InputEventJoypadMotion and abs(event.axis_value) < 0.1:
		return
	var input_controller := InputController.new()
	input_controller.initialize_from_event(event)
	if input_controller.device != current_input_controller.device or input_controller.device_name != current_input_controller.device_name:
		current_input_controller = input_controller
		print("Changed Input Controller: %s#%d" % [current_input_controller.device_name, current_input_controller.device + 1])
	$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = "%s#%d" % [current_input_controller.device_name, current_input_controller.device + 1]

func on_connected_to_server():
	print("Connected to server!")
	$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "Connected"
	$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.darkgreen
	
	# Tell everybody which players are connected locally here.
	print("TODO Tell the others who is connected here...")
	announce_local_players()

func on_connection_failed():
	print("Connection failed!")
	$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "Connection failed"
	$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.red
	$VBoxContainer/Network/BtnClient.pressed = false
	get_tree().network_peer = null
	
func on_network_peer_connected(peer_id: int):
	print("Peer connected: ", peer_id)
	# Now we want the peer to tell us which players are local there.
	# But probably it doesn't work this way.
	# Instead, the peer tells everybody who is connected there
	# when it is connected.
	if get_tree().get_network_unique_id() == 1 and peer_id > 1:
		announce_players(Players.connected.values(), peer_id)


func on_network_peer_disconnected(id: int):
	print("Peer disconnected: ", id)


func on_server_disconnected():
	print("Server disconnected")
	$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "Server disconnected."
	$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.red
	$VBoxContainer/Network/BtnClient.pressed = false
	get_tree().network_peer = null


func _on_PlayerName_text_changed(new_text: String):
	print("Name changed: ", new_text)


func _on_BtnLocal_pressed():
	if get_tree().network_peer != null:
		print("TODO: Tell the others that we're leaving!")
		rpc("Leaving the network")
		get_tree().network_peer = null
	
	var local_players = get_local_players()
	for ap in Players.connected:
		if not (local_players.has(ap)):
			leave_party(ap.network_player)
		else:
			ap.peer_id = -1
	$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "(Local Game)"
	$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.darkgray
	get_tree().network_peer = null


func _on_BtnServer_pressed():
	server_host = $VBoxContainer/Network/TxtHost.text
	server_port = $VBoxContainer/Network/TxtPort.text as int
	print("TODO: Automatic saving of server host and port!")
	print("Starting Server ", server_host, ":", server_port, " -- Note that the host is actually ignored!")
	var peer = NetworkedMultiplayerENet.new()
	# Check that server_host is valid
	if server_host != "*":
		print("TODO Check that host IP is valid.")
	peer.set_bind_ip(server_host)
	var error = peer.create_server(server_port, MAX_PLAYERS)
	if error == OK:
		get_tree().network_peer = peer
		var local_peer_id = get_tree().get_network_unique_id()
		for ap in Players.connected:
			if ap.peer_id > 0 and ap.peer_id != local_peer_id:
				leave_party(ap.network_player)
			else:
				ap.peer_id = local_peer_id
	
		$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "Server listening on port %s" % server_port
		$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.darkgreen
		show_our_network_role()
	else:
		$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "Error starting server: %s" % error
		$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.red


func _on_BtnClient_pressed():
	server_host = $VBoxContainer/Network/TxtHost.text
	server_port = $VBoxContainer/Network/TxtPort.text as int
	print("TODO: Automatic saving of server host and port!")
	print("Starting Client, connecting to ", server_host, ":", server_port)
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_host, server_port)
	get_tree().network_peer = peer
	var local_peer_id = get_tree().get_network_unique_id()
	for ap in Players.connected:
		if ap.peer_id > 0 and ap.peer_id != local_peer_id:
			leave_party(ap.network_player)
		else:
			ap.peer_id = local_peer_id
	$VBoxContainer/NetworkInfo/ColorServerStatus/ServerStatus.text = "Connecting to %s:%s ..." % [server_host, server_port]
	$VBoxContainer/NetworkInfo/ColorServerStatus.color = Color.orange
	show_our_network_role()
	

func show_our_network_role():
	print("Our network role is: Server? " + (get_tree().is_network_server() as String) + ", unique id=", get_tree().get_network_unique_id())


func _on_BtnAdd_pressed():
	# Create a new local profile.
	$DlgCreateProfile.initialize(null)
	$DlgCreateProfile.popup_centered()


func _on_DlgCreateProfile_profile_created(nw_player: NetworkPlayer):
	print("New profile created: ", nw_player.nickname)
	show_local_profile(nw_player)


func _on_DlgCreateProfile_profile_edited(nw_player: NetworkPlayer):
	print("Profile edited: ", nw_player.nickname)
	for pn in $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles.get_children():
		if pn.name.begins_with("Icon") and pn.global_id == nw_player.global_id:
			update_local_profile_button(pn, nw_player)


func find_local_profile(global_id: String) -> NetworkPlayer:
	for nw_player in local_profiles:
		if nw_player.global_id == global_id:
			return nw_player
	return null


func _on_DummyPlayer_long_released(global_id):
	print("Button long released", global_id)


func _on_DummyPlayer_long_pressed(global_id):
	var nw_player = find_local_profile(global_id)
	print("Button long pressed", nw_player.nickname)
	assert(nw_player in local_profiles)
	$DlgCreateProfile.initialize(nw_player)
	$DlgCreateProfile.popup_centered()


func _on_DummyPlayer_clicked(global_id):
	print("on_Dummy_Player_clicked")
	var nw_player = find_local_profile(global_id)
	join_party(nw_player)


func join_party(nw_player: NetworkPlayer):
	# if no controller is selected, player cannot join
	if current_input_controller.device_name.empty():
		var msg = "Please use the keyboard or a gamepad - using the mouse is not supported."
		$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = msg
		return
	# if controller is already in use, player cannot join
	for ap in Players.connected.values():
		var ap_controller := ap.controller as InputController
		if ap_controller.type == current_input_controller.type and ap_controller.device == current_input_controller.device:
			var msg := "The current controller %s#%s is already used by %s!" % [current_input_controller.device_name, current_input_controller.device + 1, ap.nickname]
			$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = msg
			return
	var controller := InputController.new()
	controller.type = current_input_controller.type
	controller.device = current_input_controller.device
	controller.device_name = current_input_controller.device_name
	var peer_id = -1
	if get_tree().network_peer is NetworkedMultiplayerPeer:
		peer_id = get_tree().get_network_unique_id()
	var result = Players.connect("player_added", self, "player_added", [], CONNECT_ONESHOT)
	print("Connect result: ", result)
	var ap := AdaptedPlayer.new(nw_player, peer_id, controller)
	Players.add(ap)


func player_added(ap: AdaptedPlayer):
	
	if get_tree().is_network_server():
		if is_local(ap):
			announce_local_players()
		elif get_tree().is_network_server():
			# Announce the new player to all other peers
			announce_players([ap])	
	
	var container := $VBoxContainer/ConnectedPlayers
	var height := 200
	var width := 150
	var vpc := ViewportContainer.new()
	var index := container.get_child_count()
	vpc.rect_min_size.x = width
	vpc.rect_min_size.y = height
	vpc.name = "PodestScene#%d" % index
	podest_vpcs[ap.global_id] = vpc.name
	vpc.visible = true
	vpc.set_focus_mode(Control.FOCUS_ALL)
	container.add_child(vpc)
	var vp := Viewport.new()
	vp.size.x = width
	vp.size.y = height
	vp.own_world = true
	vp.name = "VPPodestScene#%d" % index
	vpc.add_child(vp)
	var podest := podest_scene.instance()
	podest.name = "ScnPodestScene#%d" % index
	var gardener: Gardener = podest.get_node("Gardener")
	gardener.setup_avatar(ap)
	gardener.can_run = false
	vp.add_child(podest)
	gardener.direction_global = gardener.transform.basis.z

	#var cam_template: Camera = vpc_template.get_node("Viewport/Camera")
	#var camera := Camera.new()
	#camera.transform = cam_template.transform
	#camera.name = "CamPodestScene#%d" % index
	#vp.add_child(camera)
	print("'Hello' from %s" % gardener.nickname)
	gardener.get_node("AnimationPlayer").play("Emote1")
	podest.get_node("LblController").text = "%s %s#%d" % [ap.in_game_uid, ap.controller.device_name, ap.controller.device + 1]
	var lbl_hint = vpc_template.get_node("LblHint").duplicate()
	vpc.add_child(lbl_hint)
	var anim = vpc_template.get_node("AnimationPlayer").duplicate()
	vpc.add_child(anim)
	on_connected_player_not_ready(gardener, anim, lbl_hint, ap, true)


func on_connected_player_not_ready(gardener, anim: AnimationPlayer, lbl_hint: RichTextLabel, ap: AdaptedPlayer, first_time: bool = false):
	if first_time:
		print("Player is not yet ready: ", ap.nickname)
	else:
		print("Player is no longer ready: ", ap.nickname)
	lbl_hint.text = "Press Jump\nwhen ready"
	ap.controller.enable_for_ui(false)
	gardener.connect("jump", self, "on_connected_player_ready", [gardener, anim, lbl_hint, ap], CONNECT_ONESHOT)
	gardener.connect("cancel_pressed", self, "on_connected_player_cancel", [ap], CONNECT_ONESHOT)
	anim.play("PressOkGlow")
	players_not_ready.append(ap.global_id)
	print("Players not ready: ", players_not_ready)


func on_connected_player_cancel(ap: AdaptedPlayer):
	print("Player cancelled: ", ap.nickname)
	ap.controller.enable_for_ui(true)
	var container := $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles
	for btn in container.get_children():
		if btn.name.begins_with("Icon#") and btn.global_id == ap.global_id:
			btn.grab_focus()
	leave_party(ap)

	
func on_connected_player_ready(gardener, anim: AnimationPlayer, lbl_hint: RichTextLabel, ap: AdaptedPlayer):
	print("Player is ready: ", ap.nickname)
	lbl_hint.text = "Ready"
	gardener.connect("cancel_pressed", self, "on_connected_player_not_ready", [gardener, anim, lbl_hint, ap], CONNECT_ONESHOT)
	anim.play("ReadyGlow")
	print("Players not ready: ", players_not_ready)
	var i := players_not_ready.find(ap.global_id)
	if i >= 0:
		players_not_ready.remove(i)
		if players_not_ready.empty():
			start_game()
		else:
			print("Still waiting for:")
			for p in players_not_ready:
				print("  %s" % p)
	else:
		push_error("Tried to remove player %s (%s) from waiting list, but player is not on that list" % [ap.nickname, ap.global_id])


func leave_party(ap: AdaptedPlayer) -> void:
	var _result = Players.connect("player_removed", self, "player_removed", [], CONNECT_ONESHOT)
	Players.remove(ap.global_id)
	
	

func find_podest_vpc(global_id: String) -> ViewportContainer:
	return $VBoxContainer/ConnectedPlayers.get_node(podest_vpcs[global_id])	as ViewportContainer


func player_removed(ap: AdaptedPlayer) -> void:
	ap.controller.disable()
	ap.controller = null
	players_not_ready.erase(ap.global_id)
	var vpc = find_podest_vpc(ap.global_id)
	vpc.queue_free()
	if is_local(ap):
		announce_local_players()


func start_game() -> void:
	var button_group: ButtonGroup = $VBoxContainer/Network/BtnLocal.group
	var game_type := button_group.get_pressed_button().name.substr(3)
	print("Start Game, game type:", game_type)
	
	var local_players = get_local_players()
	
	if game_type == "Local":
		GameSettings.network = false
	else:
		GameSettings.network = true
	if len(local_players) > 2:
		push_error("Max. 2 players allowed on a single machine.")
		return

	# print("Disabling new network connections...")
	get_tree().set_refuse_new_network_connections(false)

	GameSettings.local_players = local_players
	GameSettings.num_viewports = len(local_players)
	GameSettings.single_player_mode = (not GameSettings.network and len(local_players) == 1)
	print ("Starting game:")
	print("  Single_player=", GameSettings.single_player_mode)
	print("  Network type=", game_type)
	print("  # ViewPorts=", GameSettings.num_viewports)

	var screen = preload("res://Splitscreen.tscn")
	if get_tree().change_scene_to(screen) != OK:
		push_error("Unable to start scene")


func is_local(ap: AdaptedPlayer) -> bool:
	var local_peer_id = -1
	if get_tree().has_network_peer():
		local_peer_id = get_tree().get_network_unique_id()
	return ap.peer_id == local_peer_id


func get_local_players() -> Array:
	# How many players are local players?
	var local_players = []
	print("Local players ")
	for ap in Players.connected.values():
		if is_local(ap):
			local_players.append(ap)
			print("    ", ap.nickname)
	return local_players


func announce_local_players():
	if not get_tree().has_network_peer():
		return
	announce_players(get_local_players())


func announce_players(players: Array, peer_id = null) -> void:
	var announced_players := []
	for ap in players:
		var msg := EnterLobby.new()
		msg.nickname = ap.nickname
		msg.global_id = ap.global_id
		msg.in_game_uid = ap.in_game_uid
		msg.peer_id = ap.peer_id
		msg.color = ap.color
		msg.second_color = ap.second_color
		announced_players.append(msg.to_array())
		if get_tree().is_network_server():
			assert(msg.in_game_uid)
	print("Announcing players to the other peers: ", announced_players)
	if peer_id == null:
		rpc("recv_announced_players", announced_players)
	else:
		rpc_id(peer_id, "recv_announced_players", announced_players)


func parse_announced_player(msg: EnterLobby, from_peer_id: int) -> AdaptedPlayer:
	var nw_player := NetworkPlayer.new()
	nw_player.nickname = msg.nickname
	nw_player.global_id = msg.global_id
	var controller := InputController.new()
	controller.type = InputController.REMOTE
	controller.device = from_peer_id
	controller.device_name = "[Remote]"
	var ap := AdaptedPlayer.new(nw_player, from_peer_id, controller)
	ap.nickname = msg.nickname
	# Fixme Color handling is somewhat broken
	nw_player.fav_color1 = msg.color
	nw_player.fav_color2 = msg.second_color
	ap.color = msg.color
	ap.second_color = msg.second_color
	ap.in_game_uid = msg.in_game_uid
	return ap


remote func recv_announced_players(announced_players: Array):

	var peer_id := get_tree().get_rpc_sender_id()
	#if peer_id == get_tree().get_network_unique_id():
	#	print("Ignored RPC call from self: %s", "announce_players")
	#	return
	print("Players announced from peer #%d: %s" % [peer_id, len(announced_players)])
	# Remove players that are still in our list but not no longer on the peer's list
	var remote_global_ids := []
	var previous_global_ids := []
	if Players.peers.has(peer_id):
		previous_global_ids = Players.peers[peer_id]
	var ap_array := []
	for p in announced_players:
		var ap := parse_announced_player(EnterLobby.new(p), peer_id)
		ap_array.append(ap)
		remote_global_ids.append(ap.global_id)
	for global_id in previous_global_ids:
		if not (global_id in remote_global_ids):
			Players.remove(global_id)
	# Add players that are on the peer's list, but not on our list
	for remote_ap in ap_array:
		if not (remote_ap.global_id in previous_global_ids):
			Players.add(remote_ap)
			player_added(remote_ap)
		else:
			print("TODO: Handle editing of remote players, eg by version numbering?")


remotesync func assign_in_game_uids(d: Dictionary):
	for global_id in d.keys():
		var ap := Players.find(global_id)
		if ap != null:
			ap.in_game_uid = d[global_id]
