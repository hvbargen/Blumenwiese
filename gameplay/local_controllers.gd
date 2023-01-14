extends Node


# class_name LocalControllers


var controllers: Array = []


func register(type, device) -> int:
	for i in range(len(controllers)):
		var c := controllers[i] as Array
		if c[0] == type  and c[1] == device:
			return i
	var id := len(controllers)
	controllers.append([type, device])
	return id
