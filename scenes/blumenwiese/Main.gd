extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var seed_scene
export (PackedScene) var flower_scene

const Logger = preload("res://util/Logger.gd")
var logger := Logger.new("Main")

onready var spawn_positions := $SpawnPositions as Spatial

onready var gardener_template := $GardenerTemplate as Gardener

export var gardener_scene = preload("res://avatars/gardener/Gardener.tscn") 

var free_spawn_positions := []

# Called when the node enters the scene tree for the first time.
func _ready():
	var f := $Testflower/Flower
	f.spawn_leafs(0.5)
	f.spawn_blossom(1)
	$"Testpflanze/Blüte".grow(2)
	
	free_spawn_positions = spawn_positions.get_children()

	if not GameSettings.local_players.empty():
		remove_child(gardener_template)
		for i in range(len(GameSettings.local_players)):
			var ap: AdaptedPlayer = GameSettings.local_players[i]
			var _avatar = spawn_player(ap)
	else:
		init_dummy(2)


func _on_Gardener_spawned_seed(who: Gardener):
	logger.debug("%s Spawning seed...", who.name)
	var new_seed = seed_scene.instance()
	var t = who.translation
	t.y += 1.8
	var ig_player_id := who.get_ig_player_id()
	new_seed.initialize(t, ig_player_id)
	add_child(new_seed)
	new_seed.connect("seed_sunken", self, "_on_Seed_seed_sunken")


func _on_Seed_seed_sunken(where, color: Color):
	logger.debug("Seed sunken at %s, color is %s", where, color)
	var new_flower = flower_scene.instance()
	new_flower.initialize(where, color)
	add_child(new_flower)
	new_flower.begin_growing()


func spawn_player(ap: AdaptedPlayer) -> Gardener:
	var spawn_position: Spatial = free_spawn_positions.pop_front()
	var avatar := gardener_scene.instance() as Gardener
	avatar.name = "Player#%s" % ap.get_ig_player_id()
	avatar.setup_avatar(ap)
	add_child(avatar)
	avatar.transform = spawn_position.transform
	avatar.direction_global = avatar.transform.basis.z
	avatar.set_network_master(1)
	
	avatar.connect("spawned_seed", self, "_on_Gardener_spawned_seed")
	
	return avatar

func init_dummy(one_or_two: int):
	# Dummy scene with two players,
	remove_child(gardener_template)

	var nw = PlayerProfile.new()

	nw.global_id = "id1"
	nw.nickname = "Dummy 1"
	nw.fav_color1 = Color.red
	nw.fav_color2 = Color.white
	var controller = InputController.new()
	controller.initialize_dummy(InputController.KEYBOARD)
	var ap1 = AdaptedPlayer.new(nw, 0, controller)
	var player1 = spawn_player(ap1)

	if one_or_two == 2:
		nw.global_id = "id2"
		nw.nickname = "Dummy 2"
		nw.fav_color1 = Color.yellow
		nw.fav_color2 = Color.blue
		controller = InputController.new()
		controller.initialize_dummy(InputController.GAMEPAD)
		var ap2 = AdaptedPlayer.new(nw, 0, controller)
		var _player2 = spawn_player(ap2)

	nw.global_id = "id3"
	nw.nickname = "Remoty Dummy"
	nw.fav_color1 = Color.green
	nw.fav_color2 = Color.red
	controller = InputController.new()
	controller.initialize_dummy(InputController.REMOTE)
	var _remote_ap = spawn_player(AdaptedPlayer.new(nw, 0, controller))
	
	player1.get_node("3rdPerson/Camera").current = true
	print("Using dummy with %s Lobby." % one_or_two)
