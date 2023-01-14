extends Resource

class_name InputController

export var type: String
export var device: int
export var device_name: String = ""
export var ig_player_id: int
export var enabled: bool = false setget set_enable

var controller_id: int = -1 # means not yet registered

const GAMEPAD := "Gamepad"
const KEYBOARD := "Keyboard"
const REMOTE := "[Remote]"

const actions := [ "turn_left", "turn_right", "forward", "jump", "cancel" ]

var ui_disabled_actions = {}

func initialize_from_event(event: InputEvent) -> void:
	if event is InputEventMouse:
		push_error("Mouse control is not supported")
	elif event is InputEventJoypadMotion and abs(event.axis_value) < 0.1:
		push_error("Ignored Joypad noise")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		type = GAMEPAD
		device = event.device
		device_name = Input.get_joy_name(event.device)
		LocalControllers.register(self)
	elif event is InputEventKey:
		type = KEYBOARD
		device = event.device
		device_name = KEYBOARD
		LocalControllers.register(self)
	else:
		push_error("Cannot use input event for controller initialization: %s" % event)
		

func initialize_dummy(a_type = KEYBOARD) -> void:
	type = a_type
	device = 0
	device_name = "Dummy-" + type
	set_ig_peer_id(0)
	LocalControllers.register(self)


func disable():
	if enabled:
		enabled = false
		for action in actions:
			var action_name := "%s#%s" % [action, ig_player_id]
			if InputMap.has_action(action_name):
				InputMap.erase_action(action_name)


func enable_for_ui(on: bool = true):
	print("Controller ", device_name, " enable_for_ui=", on)
	if on:
		for action in ui_disabled_actions.keys():
			for event in ui_disabled_actions[action]:
				InputMap.action_add_event(action, event)
		ui_disabled_actions.clear()
	else:
		for action in InputMap.get_actions():
			if not action.begins_with("ui_"):
				continue
			for event in InputMap.get_action_list(action).duplicate():
				# duplicate is necessary because modifying a Dictionary while
				# iterating over it is not supported.
				if ((event is InputEventKey and type == KEYBOARD)
				or ((event is InputEventJoypadButton or event is InputEventJoypadMotion)
					and type == GAMEPAD
					and event.device == device)
				):
					if not ui_disabled_actions.has(action):
						ui_disabled_actions[action] = [event]
					else:
						ui_disabled_actions[action].append(event)
					InputMap.action_erase_event(action, event)
					#print("removed %s event %s" % [action, event.as_text()])
	
func set_enable(on: bool = true):
	print("Controller ", device_name, " enable => ", on)
	if enabled:
		disable()
	print("Enabling controller %s for player %s" % [device_name, ig_player_id])
	enabled = on
	if not on:
		return

	if type == GAMEPAD:

		# turn_left
		var action_name := "%s#%s" % ["turn_left", ig_player_id]
		InputMap.add_action(action_name)
		var dpad_event := InputEventJoypadButton.new()
		dpad_event.button_index = JOY_DPAD_LEFT
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)
		var stick_event := InputEventJoypadMotion.new()
		stick_event.axis = JOY_ANALOG_LX
		stick_event.axis_value = -1.0
		stick_event.device = device
		InputMap.action_add_event(action_name, stick_event)

		# turn_right
		action_name = "%s#%s" % ["turn_right", ig_player_id]
		InputMap.add_action(action_name)
		dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_DPAD_RIGHT
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)
		stick_event = InputEventJoypadMotion.new()
		stick_event.axis = JOY_ANALOG_LX
		stick_event.axis_value = 1.0
		stick_event.device = device
		InputMap.action_add_event(action_name, stick_event)

		# forward
		action_name = "%s#%s" % ["forward", ig_player_id]
		InputMap.add_action(action_name)
		dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_DPAD_UP
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)
		stick_event = InputEventJoypadMotion.new()
		stick_event.axis = JOY_ANALOG_LY
		stick_event.axis_value = -1.0
		stick_event.device = device
		InputMap.action_add_event(action_name, stick_event)

		# jump
		action_name = "%s#%s" % ["jump", ig_player_id]
		InputMap.add_action(action_name)
		dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_SONY_X
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)

		# cancel
		action_name = "%s#%s" % ["cancel", ig_player_id]
		InputMap.add_action(action_name)
		dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_SONY_CIRCLE
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)

	if type == KEYBOARD:

		# turn_left
		var action_name := "%s#%s" % ["turn_left", ig_player_id]
		InputMap.add_action(action_name)
		var key_event := InputEventKey.new()
		key_event.scancode = KEY_LEFT
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# turn_right
		action_name = "%s#%s" % ["turn_right", ig_player_id]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_RIGHT
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# forward
		action_name = "%s#%s" % ["forward", ig_player_id]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_UP
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# jump
		action_name = "%s#%s" % ["jump", ig_player_id]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_SPACE
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# cancel
		action_name = "%s#%s" % ["cancel", ig_player_id]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_ESCAPE
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)
		
		
func set_ig_peer_id(ig_peer_id: int):
	print("Controller " + device_name + ": setting ig_peer_id = ", ig_peer_id)
	if enabled:
		disable()
	ig_player_id = ig_peer_id * 10 + controller_id
	if type != REMOTE:
		set_enable(true)
