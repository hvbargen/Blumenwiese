extends Spatial

export var color: Color

const Logger = preload("res://util/Logger.gd")
var logger: Logger

func _init():
	._init()
	logger = Logger.new("Blossom")
	logger.name += (get_instance_id() as String)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func initialize(position: Vector3, blossom_color: Color, anzahl: int, winkel: float):
	self.color = blossom_color
	var blr = $Blossom/BlossomLeafRing
	blr.anzahl = anzahl
	blr.winkel_deg = winkel
	blr.breite = rand_range(0.3, 0.9)
	self.translate(position)
	var bl = $Blossom/BlossomMesh
	var mesh: Mesh  = bl.mesh
	var mat: ShaderMaterial = mesh.surface_get_material(0).duplicate()
	mat.set_shader_param("albedo", color)
	mat.set_shader_param("transmission", color.darkened(0.3))
	
	mesh.surface_set_material(0, mat)
	#bl.set_surface_material(0,mat)
	logger.debug("Blüte initialisiert mit Anzahl %s, Winkel %s, at %s", anzahl, winkel, self.translation)

func grow(duration: float):
	#logger.warn("Growing is disabled")
	#return
	var tween = $Tween
	var blr = $Blossom/BlossomLeafRing
	tween.interpolate_property(blr, "scale", Vector3.ZERO, Vector3.ONE, duration, Tween.TRANS_LINEAR)
	tween.start()
