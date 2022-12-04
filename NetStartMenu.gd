extends Control


const MAX_PLAYERS := 4

var server_port := 9000

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var mp = get_tree().multiplayer
	mp.connect("server_disconnected", self, "on_server_disconnected")
	mp.connect("connected_to_server", self, "on_connected_to_server")
	mp.connect("connection_failed", self, "on_connection_failed")
	mp.connect("network_peer_connected", self, "on_network_peer_connected")
	mp.connect("network_peer_disconnected", self, "on_network_peer_disconnected")
	pass # Replace with function body.

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


func _on_BtnServer_pressed():
	var server_host = $VBoxContainer/HBoxContainer2/TxtHost.text
	server_port = $VBoxContainer/HBoxContainer2/TxtHost.text as int
	print("Starting Server ", server_host, ":", server_port, " -- Note that the host is actually ignored!")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(server_port, MAX_PLAYERS)
	get_tree().network_peer = peer
	show_our_network_role()

func _on_BtnClient_pressed():
	var server_host = $VBoxContainer/HBoxContainer2/TxtHost.text
	server_port = $VBoxContainer/HBoxContainer2/TxtHost.text as int
	print("Starting Client, connecting to ", server_host, ":", server_port)
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_host, server_port)
	get_tree().network_peer = peer
	show_our_network_role()
	
func show_our_network_role():
	print("Our network role is: Server? " + (get_tree().is_network_server() as String) + ", unique id=", get_tree().get_network_unique_id())

