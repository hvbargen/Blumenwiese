extends Spatial

var controller: InputController setget set_controller

func set_controller(new_controller: InputController):
	controller = new_controller
	$LblController.text = "%s#%s" % [controller.device_name, (controller.device + 1)]
