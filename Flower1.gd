extends Spatial

const Logger = preload("Logger.gd")
var logger: Logger

export var color: Color

func _init():
	._init()
	logger = Logger.new("Flower1")
	logger.level = Logger.Level.DEBUG
	logger.name += (get_instance_id() as String)
	
func initialize(position: Vector3, color: Color):
	self.translate(position)
	self.color = color
	logger.debug("Initialized flower at %s", transform.origin)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("AnimationPlayer").play("YoungGrow")
	logger.debug("Started animation")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	logger.debug("Animation %s finished", anim_name)
