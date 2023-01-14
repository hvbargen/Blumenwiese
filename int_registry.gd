extends Reference

class_name IntRegistry

var _arr: PoolIntArray

const INVALID := -1

func _init():
	_arr = PoolIntArray()

func register(long_id: int) -> int:
	if _arr.find(long_id) >= 0:
		push_error("This long id is already registered: " + String(long_id))
		return INVALID
	_arr.append(long_id)
	return len(_arr)
	
func unregister(long_id) -> int:
	var idx := _arr.find(long_id)
	if idx < 0:
		push_error("This long id was not registered: " + String(long_id))
	elif idx == len(_arr) - 1:
		_arr.remove(idx)
	else:
		_arr.set(idx, INVALID)
	return idx


func get_short(long_id: int) -> int:
	var idx := _arr.find(long_id)
	if idx < 0:
		push_error("This long id was not registered: " + String(long_id))
		return INVALID
	return idx


func get_long(short_id: int) -> int:
	return _arr[short_id]
	
	
func overrule(long_id: int, short_id: int) -> void:
	assert(_arr.find(long_id) < 0)
	if len(_arr) < short_id + 1:
		var old_len := len(_arr)
		_arr.resize(short_id + 1)
		for i in range(old_len, short_id):
			_arr.set(i, INVALID)
	assert(_arr[short_id] == INVALID)
	_arr.set(short_id, long_id)


func clear() -> void:
	_arr = PoolIntArray()
