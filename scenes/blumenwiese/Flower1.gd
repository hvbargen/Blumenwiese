extends Spatial

const Logger = preload("res://util/Logger.gd")
var logger: Logger

export var color: Color = Color8(230, 0, 20)

export (PackedScene) var blossom_scene
export (PackedScene) var leaf_scene

func _init():
	._init()
	logger = Logger.new("Flower1")
	logger.name += (get_instance_id() as String)
	
func initialize(position: Vector3, blossom_color: Color):
	self.translate(position)
	self.color = blossom_color
	logger.debug("Initialized flower at %s", transform.origin)
	
func begin_growing():
	var anim = get_node("AnimationPlayer")
	anim.play("YoungGrow")
	logger.debug("AnimationPlayer %s started animation" % anim.get_instance_id())
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	logger.debug("Animation %s finished", anim_name)
	
func spawn_leafs(height: float):
	logger.debug("Spawn leafs")
	var sc = leaf_scene.instance()
	var anzahl = 2 + randi() % 5
	var winkel = rand_range(30, 100)
	sc.initialize(anzahl, winkel)
	sc.translate(Vector3.UP * height)
	add_child(sc)
	sc.grow(2.0)
	
func spawn_blossom(height: float):
	logger.debug("Spawn blossom at height %s", height)
	var sc = blossom_scene.instance()
	var anzahl = 4 + randi() % 5
	var winkel = rand_range(30, 100)
	var spawn_location = $Wurzel/Stiel.translation
	spawn_location.y += height
	logger.debug("Blossom (%s) spawning at %s", anzahl, spawn_location)
	sc.initialize(spawn_location, color, anzahl, winkel)
	add_child(sc)
	sc.grow(2.0)
