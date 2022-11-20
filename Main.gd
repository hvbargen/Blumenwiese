extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var seed_scene


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Gardener_spawned_seed():
	print("Spawning seed...")
	var spawn_location = get_node("Gardener")
	var new_seed = seed_scene.instance()
	var t = spawn_location.translation
	t.y += 1.8
	new_seed.initialize(t)
	add_child(new_seed)
