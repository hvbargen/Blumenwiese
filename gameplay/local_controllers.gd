extends Node


# class_name LocalControllers


var controllers: Array = []


func register(controller: InputController) -> void:
	for i in range(len(controllers)):
		var c := controllers[i] as InputController
		if c.type == controller.type and c.device == controller.device:
			controller.controller_id = i
	var id := len(controllers)
	controller.controller_id = id
	controllers.append(controller)
