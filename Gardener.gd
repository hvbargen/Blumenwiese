extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var max_speed = 6.0 # m/s
export var turn_speed = 1.5 * PI #
export var gravity = 9.81 # m/s²
export var accel = 7.0  # m/s²
export var break_accel = 7.0 # m/s²
export var jump_accel = 300.0 # m/s

signal spawned_seed

var direction = Vector3.FORWARD
var velocity = Vector3.ZERO
var running = false
var anim : AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	anim = get_node("Pivot/Spatial/3DGodotRobot/AnimationPlayer")
	anim.play("Idle-loop")
	

func _physics_process(delta):
	handle_input(delta)
	
	
func handle_input(delta):
	var forward = 0
	var turn = 0
	var jump = false
	var on_floor = is_on_floor()
	if Input.is_action_pressed("forward"):
		forward += 1
	if Input.is_action_pressed("backward"):
		forward -= 1;
	if Input.is_action_pressed("turn_right"):
		turn += 1
	if Input.is_action_pressed("turn_left"):
		turn -= 1
	if Input.is_action_pressed("jump"):
		jump = true
		
	# Turn
	direction = direction.normalized()
	if turn != 0:
		var angle = - turn * turn_speed * delta
		$Pivot.rotate_y(angle)
		direction = direction.rotated(Vector3.UP, angle)

	var delta_velocity2d = Vector2.ZERO
	var direction2d: Vector2
	
	direction2d.x = direction.x
	direction2d.y = - (direction.z)
	direction2d = direction2d.normalized()

	var velocity2d = Vector2.ZERO
	velocity2d.x = velocity.x
	velocity2d.y = - (velocity.z)

	if on_floor:	
		if forward > 0:
			running = true
			delta_velocity2d = direction2d * delta * accel 
			velocity2d += delta_velocity2d
			velocity2d = velocity2d.limit_length(max_speed)
		else:
			running = false
			delta_velocity2d = velocity2d.normalized() * delta * -break_accel
			if delta_velocity2d.length_squared() > velocity2d.length_squared():
				velocity2d = Vector2.ZERO
				if forward < 0:
					pass # TODO 180° Turn
			else:
				velocity2d += delta_velocity2d
	
	# Select the right animation.
	if forward > 0:
		if on_floor and velocity2d.length_squared() > max_speed * max_speed / 0.7:
			anim.play("Sprint-loop")
		else:
			anim.play("Run-loop")
	else:
		if on_floor:
			if velocity2d.length_squared() < 0.1:
				anim.play("Idle-loop")
			else:
				anim.play("GroundSlide")
		else:	
			anim.play("Jump")

	# Move the player
	velocity.x = velocity2d.x
	velocity.z = - (velocity2d.y)
	if jump and on_floor:
		velocity.y = jump_accel * delta
		emit_signal("spawned_seed")
	else:
		velocity.y -= gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if translation.y < - 30:
		emit_signal("out_of_bounds")
		queue_free()
		print("Fallen below ground...")
	
