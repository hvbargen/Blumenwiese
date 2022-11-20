extends RigidBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var torque = Vector3.ZERO
	torque.x = rand_range(-0.2, 0.2)
	torque.y = rand_range(-0.2, 0.2)
	torque.z = rand_range(-0.2, 0.2)
	self.apply_torque_impulse(torque)
	var impulse = Vector3.ZERO
	impulse.x = rand_range(-1.0, 1.0)
	impulse.y = rand_range(0.5, 2)
	impulse.z = rand_range(-1.0, 1.0)
	self.apply_central_impulse(impulse)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func initialize(position: Vector3):
	self.translate(position)


func _on_Seed_body_entered(body):
	print("Collision detected with ", body.name)
	self.sleeping = true
