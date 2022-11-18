extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var torque : Vector3
	torque.x = rand_range(-0.2, 0.2)
	torque.y = rand_range(-0.2, 0.2)
	torque.z = rand_range(-0.2, 0.2)
	self.apply_torque_impulse(torque)
	var impulse: Vector3
	impulse.x = rand_range(-2, 2)
	impulse.y = rand_range(0, 2)
	impulse.z = rand_range(-2, 2)
	self.apply_central_impulse(impulse)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_Seed_body_entered(body):
	print("Collision detected with ", body.name)
	self.sleeping = true
