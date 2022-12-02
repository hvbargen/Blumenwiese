extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var seed_scene
export (PackedScene) var flower_scene

const Logger = preload("Logger.gd")
var logger:= Logger.new("Main", Logger.Level.DEBUG)

var active_cam : int = 0

const camera_nodes: Array = ["Gardener1/3rdPerson/Camera", "FixedPerspective1/Camera", "Gardener2/3rdPerson/Camera", ]
var cameras : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	var f = $Testflower/Flower
	f.spawn_leafs(0.5)
	f.spawn_blossom(1)
	$"Testpflanze/Blüte".grow(2)
	
	for node_name in camera_nodes:
		cameras.append(get_node(node_name))
	
	cameras[active_cam].current = true	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Gardener_spawned_seed(who: Node):
	logger.debug("%s Spawning seed...", who.name)
	var new_seed = seed_scene.instance()
	var t = who.translation
	t.y += 1.8
	new_seed.initialize(t)
	add_child(new_seed)
	new_seed.connect("seed_sunken", self, "_on_Seed_seed_sunken")
	
func _input(event):
	if event.is_action_pressed("switch_camera"):
		switch_camera()
	
func _on_Seed_seed_sunken(where, color):
	logger.debug("Seed sunken at %s, color is %s", where, color)
	var new_flower = flower_scene.instance()
	new_flower.initialize(where, color)
	add_child(new_flower)
	new_flower.begin_growing()
	
func switch_camera():
	active_cam = (active_cam+1) % len(cameras)
	cameras[active_cam].current = true
