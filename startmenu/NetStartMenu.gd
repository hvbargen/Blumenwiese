extends Control


const MAX_PLAYERS := 4

const Logger = preload("res://util/Logger.gd")
var logger: Logger

var server_port := 9000

var player_node_template: Control

var local_profiles: Array # of NetworkPlayer

var current_input_device: Dictionary = {}

var podest_scene := preload("res://scenes/podest/Podest.tscn")

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
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		current_input_device = {
			"type": "Gamepad",
			"device": event.device,
			"device_name": Input.get_joy_name(event.device),
		}
		$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = "%s #%d: %s" % [current_input_device.type, current_input_device["device"] + 1, current_input_device["device_name"]]
		print(current_input_device)
		if event is InputEventJoypadButton:
			print(Input.get_joy_button_string(event.button_index))
	if event is InputEventKey:
		current_input_device = {
			"type": "Keyboard",
			"device": event.device,
			"device_name": "Keyboard",
		}
		$VBoxContainer/HBoxContainer/LblCurrentInputDevice.text = "%s #%d" % [current_input_device.type, current_input_device["device"] + 1]
		print(current_input_device)


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
	Players.connect("player_added", self, "player_added")
	Players.add(nw_player, get_tree().get_network_unique_id())
	
func player_added(ap: Players.AdaptedPlayer):
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
	gardener.can_run = false
	vp.add_child(podest)
	var cam_template := $VBoxContainer/ConnectedPlayers/TemplateViewPortContainer/TemplateViewport/Camera
	var camera = Camera.new()
	camera.transform = cam_template.transform
	camera.name = "CamPodestScene#%d" % ap.index
	vp.add_child(camera)
	print("Hallo!")
	

func leave_party(nw_player: NetworkPlayer):
	for ap in Players.connected:
		if ap.nw_player.global_id == nw_player.global_id:
			Players.remove(ap)
	
