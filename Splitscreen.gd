extends Node


onready var players := {
	"1": {
		viewport = $VBoxContainer/ViewportContainer1/Viewport1,
		camera = $VBoxContainer/ViewportContainer1/Viewport1/Camera1,
		player = $"VBoxContainer/ViewportContainer1/Viewport1/Main/Gardener1",
	},
	"2": {
		viewport = $VBoxContainer/ViewportContainer2/Viewport2,
		camera = $VBoxContainer/ViewportContainer2/Viewport2/Camera2,
		player = $"VBoxContainer/ViewportContainer1/Viewport1/Main/Gardener2"
	},
}


# Called when the node enters the scene tree for the first time.
func _ready():
	players["2"].viewport.world = players["1"].viewport.world
	if true:
		for player in players.values():
			var remote_transform := RemoteTransform.new()
			remote_transform.remote_path = player.camera.get_path()
			player.player.get_node("3rdPerson").add_child(remote_transform)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

