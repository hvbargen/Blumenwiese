extends Control


const MAX_PLAYERS := 4

const Logger = preload("res://util/Logger.gd")
var logger: Logger

var server_port : int = 9000

var player_node_template: Control

var local_profiles: Array # of NetworkPlayer

var current_input_controller: InputController = InputController.new()

var podest_scene := preload("res://scenes/podest/Podest.tscn")

var players_not_ready: Array = [] # of NetworkPlayer

func _init():
	._init()
	logger = Logger.new("NetStartMenu")
	logger.level = Logger.Level.DEBUG
	logger.name += (get_instance_id() as String)

# Called when the node enters the scene tree for the first time.
func _ready():
	player_node_template = $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles/DummyPlayer
	player_node_template.hide()
	var mp = get_tree().multiplayer
	mp.connect("server_disconnected", self, "on_server_disconnected")
	mp.connect("connected_to_server", self, "on_connected_to_server")
	mp.connect("connection_failed", self, "on_connection_failed")
	mp.connect("network_peer_connected", self, "on_network_peer_connected")
	mp.connect("network_peer_disconnected", self, "on_network_peer_disconnected")
	load_local_profiles()
	$VBoxContainer/Network/BtnLocal.call_deferred("grab_focus")

func load_local_profiles():
	local_profiles = NetworkPlayer.load_all_local()
	show_local_profiles()

func show_local_profiles():
	var container = $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles
	for child in container.get_children():
		if child.name.begins_with("Icon"):
			child.queue_free()
	for nw_player in local_profiles:
		show_local_profile(nw_player)
		
func show_local_profile(nw_player: NetworkPlayer):
	var container = $VBoxContainer/LocalProfiles/ScrollContainer/LocalProfiles
	print("show ", nw_player.nickname)
	var pn = player_node_template.duplicate()
	var index = container.get_child_count() - 1
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

func _input(event):
	if event is InputEventMouse:
		return
	if event is InputEventJoypadMotion and abs(event.axis_value) < 0.1:
		return
	var input_controller = InputController.new()
	input_controller.initialize_from_event(event)
	if input_controller.device != current_input_controller.device or input_controller.device_name != current_input_controller.device_name:
		current_input_controller = input_controller
		print("Changed Input Controller: %s#%d" % [current_input_controller.device_name, current_input_controller.device + 1])
	$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = "%s#%d" % [current_input_controller.device_name, current_input_controller.device + 1]

func on_connected_to_server():
	print("Connected to server!")

func on_connection_failed():
	print("Connection failed!")
	
func on_network_peer_connected(id: int):
	print("Peer connected: ", id)

func on_network_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	
func on_server_disconnected():
	print("Server disconnected")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_PlayerName_text_changed(new_text: String):
	print("Name changed: ", new_text)

func _on_BtnLocal_pressed():
	print("TODO: Local Game")

func _on_BtnServer_pressed():
	var server_host = $VBoxContainer/Network/TxtHost.text
	server_port = $VBoxContainer/Network/TxtHost.text as int
	print("Starting Server ", server_host, ":", server_port, " -- Note that the host is actually ignored!")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(server_port, MAX_PLAYERS)
	get_tree().network_peer = peer
	show_our_network_role()

func _on_BtnClient_pressed():
	var server_host = $VBoxContainer/Network/TxtHost.text
	server_port = $VBoxContainer/Network/TxtHost.text as int
	print("Starting Client, connecting to ", server_host, ":", server_port)
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_host, server_port)
	get_tree().network_peer = peer
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
	var nw_player = find_local_profile(global_id)
	print("Button clicked", nw_player.nickname)
	join_party(nw_player)

func join_party(nw_player: NetworkPlayer):
	# if no controller is selected, player cannot join
	if current_input_controller.device_name.empty():
		var msg = "Please use the keyboard or a gamepad - using the mouse is not supported."
		$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = msg
		return
	# if controller is already in use, player cannot join
	for ap in Players.connected:
		var ap_controller = ap.controller as InputController
		if ap_controller.type == current_input_controller.type and ap_controller.device == current_input_controller.device:
			var msg = "The current controller %s#%s is already used by %s!" % [current_input_controller.device_name, current_input_controller.device + 1, ap.nickname]
			$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = msg
			return
	var result = Players.connect("player_added", self, "player_added", [], CONNECT_ONESHOT)
	print("Connect result: ", result)
	var controller = current_input_controller.duplicate()
	var peer_id = -1
	if get_tree().network_peer is NetworkedMultiplayerPeer:
		peer_id = get_tree().get_network_unique_id()
	Players.add(nw_player, peer_id, controller)
	
func player_added(ap: AdaptedPlayer):
	var container = $VBoxContainer/ConnectedPlayers
	var height := 200
	var width := 150
	var vpc := ViewportContainer.new()
	vpc.rect_min_size.x = width
	vpc.rect_min_size.y = height
	vpc.name = "PodestScene#%d" % ap.index
	vpc.visible = true
	container.add_child(vpc)
	var vp := Viewport.new()
	vp.size.x = width
	vp.size.y = height
	vp.own_world = true
	vp.name = "VPPodestScene#%d" % ap.index
	vpc.add_child(vp)
	var podest = podest_scene.instance()
	podest.name = "ScnPodestScene#%d" % ap.index
	var gardener = podest.get_node("Gardener")
	gardener.nickname = ap.nw_player.nickname
	gardener.shirt_color = ap.color
	gardener.shorts_color = ap.second_color
	gardener.can_run = false
	vp.add_child(podest)
	var vpc_template := $VBoxContainer/ConnectedPlayers/TemplateViewPortContainer
	var cam_template := vpc_template.get_node("TemplateViewport/Camera")
	var camera = Camera.new()
	camera.transform = cam_template.transform
	camera.name = "CamPodestScene#%d" % ap.index
	vp.add_child(camera)
	print("'Hello' from %s" % gardener.nickname)
	gardener.get_node("AnimationPlayer").play("Emote1")
	gardener.controller = ap.controller
	gardener.controller.enable()
	podest.get_node("LblController").text = "%s#%d" % [ap.controller.device_name, ap.controller.device + 1]
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
	lbl_hint.text = "Press OK/Jump\nwhen ready"
	gardener.connect("ok_pressed", self, "on_connected_player_ready", [gardener, anim, lbl_hint, ap], CONNECT_ONESHOT)
	anim.play("PressOkGlow")
	players_not_ready.append(ap.nw_player.global_id)
	print("Players not ready: ", players_not_ready)
	
func on_connected_player_ready(gardener, anim: AnimationPlayer, lbl_hint: RichTextLabel, ap: AdaptedPlayer):
	print("Player is ready: ", ap.nickname)
	lbl_hint.text = "Ready"
	gardener.connect("cancel_pressed", self, "on_connected_player_not_ready", [gardener, anim, lbl_hint, ap], CONNECT_ONESHOT)
	anim.play("ReadyGlow")
	print("Players not ready: ", players_not_ready)
	var i = players_not_ready.find(ap.nw_player.global_id)
	if i >= 0:
		players_not_ready.remove(i)
		if players_not_ready.empty():
			start_game()
		else:
			print("Still waiting for:")
			for p in players_not_ready:
				print("  %s" % p)
	else:
		push_error("Tried to remove player %s (%s) from waiting list, but player is not on that list" % [ap.nw_player.nickname, ap.nw_player.global_id])

func leave_party(nw_player: NetworkPlayer):
	for ap in Players.connected:
		if ap.nw_player.global_id == nw_player.global_id:
			Players.remove(ap)

func start_game():
	var button_group = $VBoxContainer/Network/BtnLocal.group
	var game_type = button_group.get_pressed_button().name.substr(3)
	print("Start Game, game type:", game_type)
	
	var local_players = get_local_players()
	
	if game_type == "Local":
		GameSettings.network = false
	else:
		GameSettings.network = true
	if len(local_players) > 2:
		push_error("Max. 2 players allowed on a single machine.")
		return

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
		
func get_local_players() -> Array:

	# How many players are local players?
	var local_players = []

	print("Local players ")
	for ap in Players.connected:
		var local_peer_id = -1
		if get_tree().has_network_peer():
			local_peer_id = get_tree().get_network_unique_id()
		if ap.peer_id == local_peer_id:
			local_players.append(ap)
			print("    ", ap.nickname)
	return local_players
