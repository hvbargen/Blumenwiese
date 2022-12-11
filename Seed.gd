extends RigidBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal seed_sunken (where, color)

enum State { FLYING, SINKING, SUNKEN }

var state = State.FLYING

var start_y: float

const SINK_SPEED = 0.1

const Logger = preload("res://util/Logger.gd")
var logger: Logger

func _init():
	._init()
	logger = Logger.new("Seed")
	logger.level = Logger.Level.DEBUG
	logger.name += (get_instance_id() as String)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	var torque = Vector3.ZERO
	torque.x = rand_range(-0.2, 0.2)
	torque.y = rand_range(-0.2, 0.2)
	torque.z = rand_range(-0.2, 0.2)
	self.apply_torque_impulse(torque)
	var impulse = Vector3.ZERO
	impulse.x = rand_range(-1.0, 1.0)
	impulse.y = rand_range(0.5, 1.7)
	impulse.z = rand_range(-1.0, 1.0)
	self.apply_central_impulse(impulse)
	
	# Choose a random color
	var mesh : MeshInstance = get_node("MeshInstance")
	var material = mesh.material_override.duplicate() as SpatialMaterial
	var hue: float = randf()
	# Avoid greenish colors
	while hue > 0.23 and hue < 0.47:
		hue = randf()
	var color = Color.from_hsv(hue, rand_range(0.8, 1), rand_range(0.8, 1), rand_range(0.2, 0.8))
	material.albedo_color = color
	mesh.material_override = material

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == State.SINKING:
		transform.origin.y -= SINK_SPEED * delta
		if start_y - translation.y > 1:
			var where = transform.origin + 0.8 * Vector3.UP
			var mesh : MeshInstance = get_node("MeshInstance")
			var color = mesh.material_override.albedo_color			
			emit_signal("seed_sunken", where, color)
			logger.debug("The seed is sunken at %s, color=%s", where, color)
			state = State.SUNKEN
			queue_free()

func initialize(position: Vector3):
	self.translate(position)

func _on_Seed_body_entered(body):
	logger.debug("Collision detected with %s", body.name)
	sleeping = true
	state = State.SINKING
	start_y = transform.origin.y
	logger.debug("Start sinking at %s", transform.origin)
