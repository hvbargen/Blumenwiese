extends Node


onready var viewports = [ 
	$VBoxContainer/ViewportContainer1/Viewport,
	$VBoxContainer/ViewportContainer2/Viewport,
]

onready var main = $VBoxContainer/ViewportContainer1/Viewport/Main

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if GameSettings.num_viewports == 1:
		$VBoxContainer/ViewportContainer2.queue_free()
		$VBoxContainer/Spacer2.queue_free()
		# TODO Adapt size of Viewport 1
	else:
		viewports[1].world = viewports[0].world

	# Setup the vieport cameras
	for i in range(GameSettings.num_viewports):
		var vp = viewports[i]
		var target_cam = vp.get_node("Camera")
		var k = 0
		for p in main.get_children():
			if p is Gardener:
				if k == i:
					var src_cam = p.get_node("3rdPerson/Camera")
					var remote_transform = RemoteTransform.new()
					remote_transform.remote_path = target_cam.get_path()
					src_cam.add_child(remote_transform) 
				k += 1
	print("Splitscreen setup completed.")

