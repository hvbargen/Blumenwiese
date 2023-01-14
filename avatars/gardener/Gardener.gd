extends KinematicBody

class_name Gardener

const cloth_material = preload("res://avatars/gardener/RobotCloth.tres")

var controller: InputController

export var can_run := true
export var max_speed := 6.0 # m/s
export var turn_speed := 1.5 * PI #
export var gravity := 9.81 # m/s²
export var accel := 7.0  # m/s²
export var break_accel := 12.0 # m/s²
export var jump_accel := 300.0 # m/s
export var shirt_color := Color(0.8, 0.1, 0.1, 1.0) setget set_shirt_color
export var shorts_color := Color(1.0, 1.0, 1.0, 1.0) setget set_shorts_color
export var nickname := "<nickname>" setget set_nickname

signal out_of_bounds
signal spawned_seed(who)

signal jump
signal cancel_pressed

var direction_global := Vector3.ZERO
var velocity_global := Vector3.ZERO

var _packet_counter := -1
# -1 means that we have not yet received any packet and thus
# the first incoming packet cannot be compared for being outdatet.

enum RunState { INIT, IDLE, JUMPING, RUNNING, SPRINTING, SLIDING }

onready var run_state = RunState.INIT setget set_run_state

var anim : AnimationPlayer
var _last_input_state: InputState


func set_shirt_color(color: Color) -> void:
	shirt_color = color
	var chest: MeshInstance = $"Pivot/Spatial/3DGodotRobot/RobotArmature/Skeleton/Chest"
	var mat: Material = cloth_material.duplicate()
	mat.albedo_color = shirt_color
	chest.set_surface_material(0, mat)


func set_shorts_color(color: Color) -> void:
	shorts_color = color
	var bottom: MeshInstance = $"Pivot/Spatial/3DGodotRobot/RobotArmature/Skeleton/Bottom"
	var mat = cloth_material.duplicate()
	mat.albedo_color = shorts_color
	bottom.set_surface_material(0, mat)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_shirt_color(shirt_color)
	set_shorts_color(shorts_color)
	set_nickname(nickname)
	anim = get_node("AnimationPlayer")
	print("set direction_global")


func _physics_process(delta: float) -> void:
	var input_state := get_input()
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
	if not (controller is InputController):
		return InputState.new()
	if controller.type != InputController.REMOTE:
		return get_local_input()
	else:
		return get_remote_input()


func get_local_input() -> InputState:
	var state := InputState.new()
	state.forward = 0
	state.turn_right = 0
	state.jump_pressed = false
	state.cancel_pressed = false
	if controller is InputController and controller.enabled:
		var ig_player_id := controller.ig_player_id
		if Input.is_action_pressed("forward#%s" % ig_player_id):
			state.forward = Input.get_action_strength("forward#%s" % ig_player_id)
		if Input.is_action_pressed("turn_right#%s" % ig_player_id):
			state.turn_right += Input.get_action_strength("turn_right#%s" % ig_player_id)
		if Input.is_action_pressed("turn_left#%s" % ig_player_id):
			state.turn_right -= Input.get_action_strength("turn_left#%s" % ig_player_id)
		if Input.is_action_pressed("jump#%s" % ig_player_id):
			state.jump_pressed = true
		if Input.is_action_just_pressed("jump#%s" % ig_player_id):
			state.ok_just_pressed = true
		if Input.is_action_just_pressed("cancel#%s" % ig_player_id):
			state.cancel_just_pressed = true
		elif controller.type == InputController.REMOTE:
			print("TODO apply input from remote controllers?")
		
		publish_input(state)

		if state.cancel_just_pressed:
			emit_signal("cancel_pressed")
		
	return state


func get_remote_input() -> InputState:
	var state: InputState
	if _last_input_state is InputState:
		state = _last_input_state
	else:
		# Dummy: No movement
		state = InputState.new()

	# Consume the state, for one-time-events
	if not state.consumed:
		state.consumed = true
		state.cancel_just_pressed = false
		state.ok_just_pressed = false

	return state


func handle_input(delta: float, input_state: InputState) -> void:

	if not is_inside_tree():
		return

	var on_floor := is_on_floor()
		
	# Turn
	direction_global = direction_global.normalized()
	if input_state.turn_right != 0:
		var angle := - input_state.turn_right * turn_speed * delta
		rotate_y(angle)
		direction_global = direction_global.rotated(Vector3.UP, angle)

	var delta_velocity2d = Vector3.ZERO
	var direction2d: Vector3
	
	direction2d = direction_global
	direction2d.y = 0
	direction2d = direction2d.normalized()

	var velocity2d := Vector3.ZERO
	velocity2d = velocity_global
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
			velocity_global.y = jump_accel * delta
			emit_signal("jump", controller.ig_player_id)
			emit_signal("spawned_seed", self)
		else:
			# Move the player
			velocity_global.x = velocity2d.x
			velocity_global.z = velocity2d.z

	# Gravity
	velocity_global.y -= gravity * delta
	
	velocity_global = move_and_slide(velocity_global, Vector3.UP)
	
	if translation.y < - 30:
		emit_signal("out_of_bounds")
		queue_free()
		print("Fallen below ground...")


func _on_AnimationPlayer_animation_started(_anim_name) -> void:
	pass


func _on_AnimationPlayer_animation_finished(_anim_name) -> void:
	if run_state == RunState.INIT:
		set_run_state(RunState.IDLE)


func set_nickname(new_nickname: String) -> void:
	nickname = new_nickname
	$Pivot/Spatial/NameIndicator.text = nickname


func setup_avatar(ap: AdaptedPlayer) -> void:
	print("Setup avatar ", ap.nickname)
	set_nickname(ap.nickname)
	set_shirt_color(ap.color)
	set_shorts_color(ap.second_color)
	controller = ap.controller
	if controller.type != InputController.REMOTE and controller.ig_player_id:
		controller.enabled = true


func setup_dummy(controller_type = InputController.KEYBOARD) -> void:
	set_nickname("Dummy")
	controller = InputController.new()
	controller.initialize_dummy(controller_type)


# Send info about the input to the server
func publish_input(state: InputState) -> void:
	if controller == null:
		print("No controller, so no input")
		return
	var ig_player_id := controller.ig_player_id
	if not ig_player_id:
		print("Cannot publish input for %s, because ig_player_id is not yet set." % [nickname])
		return
	if not get_tree().has_network_peer():
		return
	_packet_counter += 1
	if (_packet_counter > 9999):
		_packet_counter = 1
		print("Packet counter wrapped around for %s" % ig_player_id )
	rpc_id(1, "upload_input_from_client", _packet_counter, ig_player_id, state.to_array())


# Receive info about the input from a peer.
# Send it to all the other clients
mastersync func upload_input_from_client(packet_no: int, ig_player_id: int, state: Array) -> void:
	var sender_id = get_tree().get_rpc_sender_id()

	assert(controller.ig_player_id == ig_player_id)
	# Sonst habe ich ein Verständnisproblem...

	if sender_id > 1 and _packet_counter >= 0:
		# Check for out-dated packets
		if packet_no > _packet_counter and packet_no < _packet_counter + 200:
			if packet_no > _packet_counter + 1:
				print("Received packet #%d, %d packets got lost and will be ignored if arriving later." % [packet_no, packet_no - _packet_counter - 1])
			else:
				pass # The perfect case
		elif packet_no < 100 and _packet_counter > 9900:
			# Wrap around
			print("Received packet #%d, old counter was %d, assuming that packets got lost and will be ignored if arriving later." % [packet_no, _packet_counter])
		elif packet_no < _packet_counter + 200:
			print("Ignoring out-dated packet %d", packet_no)
			return
		else:
			push_error("Lost sync: ´Received packet %s, current _packet_counter is" % [packet_no, _packet_counter])
			printerr("@TODO What to do now?")
			return

	if sender_id > 1:
		# TODO Validation?
		pass
		#print("TODO validation, as server received input for player %s from peer %s" % [peer_ig_player_id, sender_id])
		 
	_accept_remote_input(packet_no, state)
	
	# Send the message to all the other peers.
	rpc_unreliable("download_input_from_server", packet_no, ig_player_id, state)


# Receive info about the input from the server.
# Simlar to the code on ther server side,
# but without validation and publishing to the others.
puppet func download_input_from_server(packet_no: int, ig_player_id: int, state: Array) -> void:
	var sender_id = get_tree().get_rpc_sender_id()
	assert(sender_id == 1)
		
	if packet_no % 60 == 0:
		print("Client received input for player %s from server" % [ig_player_id])

	assert(controller.ig_player_id == ig_player_id)
	# Sonst habe ich ein Verständnisproblem...
	
	if _packet_counter >= 0:
		# Check for out-dated packets
		if packet_no > _packet_counter and packet_no < _packet_counter + 200:
			if packet_no > _packet_counter + 1:
				print("Received packet %d for player %s, %d packets got lost and will be ignored if arriving later." % [packet_no, controller.ig_player_id, packet_no - _packet_counter - 1])
			else:
				pass # The perfect case
		elif packet_no < 100 and _packet_counter > 9900:
			# Wrap around
			print("Received packet %d for player %s, old counter was %d, assuming that packets got lost and will be ignored if arriving later." % [packet_no, controller.ig_player_id, _packet_counter])
		elif packet_no < _packet_counter + 200:
			print("Ignoring out-dated packet %d for player %s" % [packet_no, controller.ig_player_id])
			return
		else:
			push_error("Lost sync: Received packet %d for player %s current _packet_counter is %d" % [packet_no, controller.ig_player_id, _packet_counter])
			printerr("@TODO What to do now?")
			return

	_accept_remote_input(packet_no, state)


func _accept_remote_input(packet_no: int, state: Array):
	#print("Accepting remote input state for ", ig_player_id)
	var input_state := InputState.new()
	_packet_counter = packet_no
	input_state.init_from_array(state)
	_last_input_state = input_state
