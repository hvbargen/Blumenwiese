extends Node


onready var viewports = [ 
	$VBoxContainer/ViewportContainer1/Viewport1,
	$VBoxContainer/ViewportContainer2/Viewport2,
]

onready var cameras = [
	$VBoxContainer/ViewportContainer1/Viewport1/Camera1,
	$VBoxContainer/ViewportContainer2/Viewport2/Camera2,
]

onready var avatars = [
	$VBoxContainer/ViewportContainer1/Viewport1/Main/Gardener1,
	$VBoxContainer/ViewportContainer1/Viewport1/Main/Gardener2,
]

onready var nicknames = [
	"Player 1",
	"Player 2",
]


# Called when the node enters the scene tree for the first time.
func _ready():
	
	if GameSettings.num_viewports == 1:
		$VBoxContainer/ViewportContainer2.queue_free()
		$VBoxContainer/Spacer2.queue_free()
		avatars[1].queue_free()
		# TODO Adapt size of Viewport 1
	else:
		viewports[1].world = viewports[0].world
		
	if true:
		for i in range(len(GameSettings.local_players)):
			var ap: AdaptedPlayer = GameSettings.local_players[i]
			var remote_transform := RemoteTransform.new()
			remote_transform.remote_path = cameras[i].get_path()
			avatars[i].get_node("3rdPerson").add_child(remote_transform)
			avatars[i].nickname = ap.nickname
			avatars[i].shirt_color = ap.color
			avatars[i].shorts_color = ap.second_color
		
			# ToDo: Setup controls
			ap.controller.enable()
			avatars[i].controller = ap.controller

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

