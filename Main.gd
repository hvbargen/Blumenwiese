extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var seed_scene
export (PackedScene) var flower_scene

const Logger = preload("Logger.gd")
var logger:= Logger.new("Main", Logger.Level.DEBUG)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Gardener_spawned_seed():
	logger.debug("Spawning seed...")
	var spawn_location = get_node("Gardener")
	var new_seed = seed_scene.instance()
	var t = spawn_location.translation
	t.y += 1.8
	new_seed.initialize(t)
	add_child(new_seed)
	new_seed.connect("seed_sunken", self, "_on_Seed_seed_sunken")


func _on_Seed_seed_sunken(where, color):
	logger.debug("Seed sunken at %s, color is %s", where, color)
	var new_flower = flower_scene.instance()
	new_flower.initialize(where, color)
	add_child(new_flower)
	
