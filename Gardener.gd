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
export var shirt_color: Color = Color(0.8, 0.1, 0.1, 1.0)

signal spawned_seed(who)

export var direction = - Vector3.FORWARD # TODO Why is minus necessary?
export var velocity = Vector3.ZERO

enum RunState { INIT, IDLE, JUMPING, RUNNING, SPRINTING, SLIDING }

onready var run_state = RunState.INIT setget set_run_state

var anim : AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	var chest: MeshInstance = $"Pivot/Spatial/3DGodotRobot/RobotArmature/Skeleton/Chest"
	
	var mat: Material = chest.get_surface_material(0).duplicate()
	mat.albedo_color = shirt_color
	chest.set_surface_material(0, mat)
	
	anim = get_node("Pivot/Spatial/3DGodotRobot/AnimationPlayer")
	anim.play("Emote1")
	$Pivot/Spatial/ForwardIndicator.translation=direction + (Vector3.UP * 0.7)
	

func _physics_process(delta):
	handle_input(delta)

func set_run_state(new_state):
	print("set_run_state ", new_state)
	run_state = new_state
	if anim != null:
		match run_state:
			RunState.INIT:
				anim.play("Emote1")
			RunState.IDLE:
				anim.play("Idle-loop")
			RunState.JUMPING:
				anim.play("Jump")
			RunState.RUNNING:
				anim.play("Run-loop")
			RunState.SPRINTING:
				anim.play("Sprint-loop")
			RunState.SLIDING: 
				anim.play("GroundSlide")

func handle_input(delta):
	var forward = 0
	var turn = 0
	var jump = false
	var on_floor = is_on_floor()
	if Input.is_action_pressed("forward"):
		forward = Input.get_action_strength("forward")
	if Input.is_action_pressed("turn_right"):
		turn += Input.get_action_strength("turn_right")
	if Input.is_action_pressed("turn_left"):
		turn -= Input.get_action_strength("turn_left")
	if Input.is_action_pressed("jump"):
		jump = true
		
	if Input.is_physical_key_pressed(KEY_E):
		anim.play("Explode")
		
	# Turn
	direction = direction.normalized()
	if turn != 0:
		var angle = - turn * turn_speed * delta
		rotate_y(angle)
		direction = direction.rotated(Vector3.UP, angle)

	var delta_velocity2d = Vector3.ZERO
	var direction2d: Vector3
	
	direction2d = direction
	direction2d.y = 0
	direction2d = direction2d.normalized()

	var velocity2d = Vector3.ZERO
	velocity2d = velocity
	velocity2d.y = 0

	if on_floor:	
		if forward > 0:
			# Run / Accelerate
			if not (run_state in [RunState.RUNNING, RunState.SPRINTING]):
				set_run_state(RunState.RUNNING)
			delta_velocity2d = direction2d * delta * accel 
			velocity2d += delta_velocity2d
			velocity2d = velocity2d.limit_length(max_speed)
			if velocity2d.length_squared() > 0.8 * (max_speed * max_speed) and run_state != RunState.SPRINTING:
				print("Start sprinting")
				set_run_state(RunState.SPRINTING)
			#print("Velocity2d=", velocity2d)
		elif run_state in [RunState.RUNNING, RunState.SPRINTING, RunState.SLIDING]:
			# Break
			if run_state != RunState.SLIDING:
				print("Start sliding")
				set_run_state(RunState.SLIDING)
			delta_velocity2d = velocity2d.normalized() * delta * -break_accel
			if delta_velocity2d.length_squared() > velocity2d.length_squared():
				velocity2d = Vector3.ZERO
				set_run_state(RunState.IDLE)
				print("Stopped!")
				if forward < 0:
					pass # TODO 180° Turn
			else:
				velocity2d += delta_velocity2d
		if jump:
			set_run_state(RunState.JUMPING)	
			velocity.y = jump_accel * delta
			emit_signal("spawned_seed", self)
		else:
			# Move the player
			velocity.x = velocity2d.x
			velocity.z = velocity2d.z

	if not jump:
		# Gravity
		velocity.y -= gravity * delta
	
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if translation.y < - 30:
		emit_signal("out_of_bounds")
		queue_free()
		print("Fallen below ground...")
	
func _on_AnimationPlayer_animation_started(anim_name):
	print("Animation started: ", anim_name)

func _on_AnimationPlayer_animation_finished(anim_name):
	print("Animation finished: ", anim_name)
	if run_state == RunState.INIT:
		set_run_state(RunState.IDLE)
