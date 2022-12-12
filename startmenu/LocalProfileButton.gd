extends Button

signal long_pressed(global_id)
signal long_released(global_id)
signal clicked(global_id)

var global_id : String
var __duration := 0.0
var __signal_sent := false


func _process(delta):
	if is_pressed():
		__duration += delta
		if __duration > 1.0 and not __signal_sent:
			emit_signal("long_pressed", global_id)
			__signal_sent = true
	else:
		if __signal_sent:
			emit_signal("long_released", global_id)
		elif __duration > 0 and __duration < 0.5:
			emit_signal("clicked", global_id)
		__signal_sent = false
		__duration = 0.0
