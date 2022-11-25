tool extends MultiMeshInstance

export var anzahl: int = 1
export var laenge: float = 1.0
export var breite: float = 0.3
export var rnd_deg: float = 5.0
export var rnd_rot_deg: float = 90.0

export(float, 0,180) var winkel_deg = 45.0 

var blatt_mesh: MeshInstance

# Called when the node enters the scene tree for the first time.
func _ready():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	blatt_mesh = $"..//BlossomMesh"
	multimesh.mesh = blatt_mesh.mesh.duplicate() # FIXME Warum ist duplicate notwendig?
	# var blatt_transform: Transform = blatt_mesh.transform
	
	# Randomness
	var r1 = rand_range(-rnd_deg, rnd_deg)
	var r2 = rand_range(-rnd_rot_deg, rnd_rot_deg) * PI / 180.0
	
	var blatt_transform: Transform = Transform.IDENTITY
	blatt_transform = blatt_transform.translated(Vector3(0, 0.5, 0))
	blatt_transform = blatt_transform.scaled(Vector3(breite, laenge, breite))
	blatt_transform = blatt_transform.rotated(Vector3.RIGHT, - (winkel_deg + r1) * PI / 180.0)
		
	multimesh.instance_count = anzahl
	
	for i in  range(anzahl):
		var t1: Transform = Transform.IDENTITY
		t1 = t1.rotated(Vector3.UP, i * 2 * PI / anzahl + r2).translated(Vector3(0, 0.3, 0))
		var t2: Transform = t1 * blatt_transform
		multimesh.set_instance_transform(i, t2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Blattkranz_visibility_changed():
	_ready()
