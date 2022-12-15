extends Resource

class_name InputController

export var index: int = -1
export var type: String
export var device: int
export var device_name: String = ""

const GAMEPAD = "Gamepad"
const KEYBOARD = "Keyboard"

const actions = [ "turn_left", "turn_right", "forward", "jump", "cancel" ]

func initialize_from_event(event: InputEvent) -> void:
	if event is InputEventMouse:
		push_error("Mouse control is not supported")
	elif event is InputEventJoypadMotion and abs(event.axis_value) < 0.1:
		push_error("Ignored Joypad noise")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		type = GAMEPAD
		device = event.device
		device_name = Input.get_joy_name(event.device)
	elif event is InputEventKey:
		type = KEYBOARD
		device = event.device
		device_name = KEYBOARD
	else:
		push_error("Cannot use input event for controller initialization: %s" % event)

func disable():
	for action in actions:
		var action_name = "%s#%d" % [action, index]
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)

func enable():
	disable()

	if type == GAMEPAD:

		# turn_left
		var action_name = "%s#%d" % ["turn_left", index]
		InputMap.add_action(action_name)
		var dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_DPAD_LEFT
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)
		var stick_event = InputEventJoypadMotion.new()
		stick_event.axis = JOY_ANALOG_LX
		stick_event.axis_value = -1.0
		stick_event.device = device
		InputMap.action_add_event(action_name, stick_event)

		# turn_right
		action_name = "%s#%d" % ["turn_right", index]
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
		action_name = "%s#%d" % ["forward", index]
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
		action_name = "%s#%d" % ["jump", index]
		InputMap.add_action(action_name)
		dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_SONY_X
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)

		# cancel
		action_name = "%s#%d" % ["cancel", index]
		InputMap.add_action(action_name)
		dpad_event = InputEventJoypadButton.new()
		dpad_event.button_index = JOY_SONY_CIRCLE
		dpad_event.device = device
		dpad_event.pressed = true
		InputMap.action_add_event(action_name, dpad_event)

	if type == KEYBOARD:

		# turn_left
		var action_name = "%s#%d" % ["turn_left", index]
		InputMap.add_action(action_name)
		var key_event = InputEventKey.new()
		key_event.scancode = KEY_LEFT
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# turn_right
		action_name = "%s#%d" % ["turn_right", index]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_RIGHT
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# forward
		action_name = "%s#%d" % ["forward", index]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_UP
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# jump
		action_name = "%s#%d" % ["jump", index]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_SPACE
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)

		# cancel
		action_name = "%s#%d" % ["cancel", index]
		InputMap.add_action(action_name)
		key_event = InputEventKey.new()
		key_event.scancode = KEY_ESCAPE
		key_event.device = device
		InputMap.action_add_event(action_name, key_event)
	
