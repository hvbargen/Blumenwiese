extends KinematicBody

const cloth_material = preload("res://avatars/gardener/RobotCloth.tres")

var controller: InputController

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var can_run = true
export var max_speed = 6.0 # m/s
export var turn_speed = 1.5 * PI #
export var gravity = 9.81 # m/s²
export var accel = 7.0  # m/s²
export var break_accel = 7.0 # m/s²
export var jump_accel = 300.0 # m/s
export var shirt_color: Color = Color(0.8, 0.1, 0.1, 1.0) setget set_shirt_color
export var shorts_color: Color = Color(1.0, 1.0, 1.0, 1.0) setget set_shorts_color
export var nickname: String = "<nickname>" setget set_nickname
export var global_id: String

signal out_of_bounds
signal spawned_seed(who)

signal ok_pressed
signal cancel_pressed

export var direction = - Vector3.FORWARD # TODO Why is minus necessary?
export var velocity = Vector3.ZERO

enum RunState { INIT, IDLE, JUMPING, RUNNING, SPRINTING, SLIDING }

onready var run_state = RunState.INIT setget set_run_state

var anim : AnimationPlayer

func set_shirt_color(color: Color):
	shirt_color = color
	var chest: MeshInstance = $"Pivot/Spatial/3DGodotRobot/RobotArmature/Skeleton/Chest"
	var mat: Material = cloth_material.duplicate()
	mat.albedo_color = shirt_color
	chest.set_surface_material(0, mat)

func set_shorts_color(color: Color):
	shorts_color = color
	var bottom: MeshInstance = $"Pivot/Spatial/3DGodotRobot/RobotArmature/Skeleton/Bottom"
	var mat = cloth_material.duplicate()
	mat.albedo_color = shorts_color
	bottom.set_surface_material(0, mat)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	set_shirt_color(shirt_color)
	set_shorts_color(shorts_color)
	set_nickname(nickname)
	anim = get_node("AnimationPlayer")
	$Pivot/Spatial/ForwardIndicator.translation=direction + (Vector3.UP * 0.7)

func _physics_process(delta):
	var input_state = get_input()
	handle_input(delta, input_state)

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

func get_input() -> InputState:
	var state = InputState.new()
	state.forward = 0
	state.turn_right = 0
	state.jump_pressed = false
	state.cancel_pressed = false	
	if controller is InputController and controller.enabled:
		var in_game_uid = controller.in_game_uid
		if Input.is_action_pressed("forward#%s" % in_game_uid):
			state.forward = Input.get_action_strength("forward#%s" % in_game_uid)
		if Input.is_action_pressed("turn_right#%s" % in_game_uid):
			state.turn_right = Input.get_action_strength("turn_right#%s" % in_game_uid) - Input.get_action_strength("turn_left#%s" % in_game_uid)
		if Input.is_action_pressed("jump#%s" % in_game_uid):
			state.jump_pressed = true
		if Input.is_action_just_pressed("jump#%s" % in_game_uid):
			state.ok_just_pressed = true
			emit_signal("ok_pressed")
		if Input.is_action_just_pressed("cancel#%s" % in_game_uid):
			state.cancel_just_pressed = true
			emit_signal("cancel_pressed")
		elif controller.type == InputController.REMOTE:
			print("TODO apply input from remote controllers?")
	return state

func handle_input(delta: float, input_state: InputState):
	var on_floor = is_on_floor()
		
	# Turn
	direction = direction.normalized()
	if input_state.turn_right != 0:
		var angle = - input_state.turn_right * turn_speed * delta
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
		if input_state.forward > 0:
			# Run / Accelerate
			if not (run_state in [RunState.RUNNING, RunState.SPRINTING]):
				set_run_state(RunState.RUNNING)
			if can_run:
				delta_velocity2d = direction2d * delta * accel * input_state.forward 
				velocity2d += delta_velocity2d
				velocity2d = velocity2d.limit_length(max_speed)
				if velocity2d.length_squared() > 0.8 * (max_speed * max_speed) and run_state != RunState.SPRINTING:
					print("Start sprinting")
					set_run_state(RunState.SPRINTING)
			#print("Velocity2d=", velocity2d)
		elif run_state in [RunState.RUNNING, RunState.SPRINTING, RunState.SLIDING, RunState.JUMPING]:
			# Break
			if run_state != RunState.SLIDING and velocity2d != Vector3.ZERO:
				print("Start sliding")
				set_run_state(RunState.SLIDING)
			delta_velocity2d = velocity2d.normalized() * delta * -break_accel
			if delta_velocity2d.length_squared() > velocity2d.length_squared() or velocity2d == Vector3.ZERO:
				velocity2d = Vector3.ZERO
				set_run_state(RunState.IDLE)
				print("Stopped!")
				if input_state.forward < 0:
					pass # TODO 180° Turn
			else:
				velocity2d += delta_velocity2d
		if input_state.jump_pressed:
			set_run_state(RunState.JUMPING)	
			velocity.y = jump_accel * delta
			emit_signal("spawned_seed", self)
		else:
			# Move the player
			velocity.x = velocity2d.x
			velocity.z = velocity2d.z

	if not input_state.jump_pressed:
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

func set_nickname(new_nickname):
	nickname = new_nickname
	$Pivot/Spatial/NameIndicator.text = nickname
