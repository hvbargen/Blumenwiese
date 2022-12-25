extends Message

class_name InputState

const PROPERTIES = ["forward", "turn_right", "jump_pressed", "ok_just_pressed", "cancel_just_pressed"]

var forward: float
var turn_right: float # -1 = turn left at full speed, 0: don't turn, +1: turn_right at full speed
var jump_pressed: bool
var cancel_pressed: bool
var ok_just_pressed: bool
var cancel_just_pressed: bool

func _init (a: Array = []):
	if not a.empty():
		init_from_array(a)

func get_properties() -> Array:
	return PROPERTIES
