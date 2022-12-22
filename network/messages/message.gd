extends Reference

class_name Message

func to_array() -> Array:
	var a := [ ]
	for prop in get_properties():
		a.append(get(prop))
	return a

func get_properties() -> Array:
	return []

func init_from_array(a: Array) -> void:
	var props = get_properties()
	for i in range(len(props)):
		set(props[i], a[i])
