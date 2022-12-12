extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func initialize(anzahl: int, winkel: float):
	var bk = $Blattkranz
	bk.anzahl = anzahl
	bk.winkel_deg = winkel
	self.scale = Vector3.ZERO
	
func grow(duration: float):
	var tween = $Tween 
	tween.interpolate_property(self, "scale", Vector3.ZERO, Vector3.ONE, duration, Tween.TRANS_LINEAR)
	tween.start()
