extends MultiMeshInstance

export var anzahl = 5
export var laenge = 3
export var winkel = PI/4

var blatt_mesh: MeshInstance

# Called when the node enters the scene tree for the first time.
func _ready():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	blatt_mesh = $"../Leaf_1/BlattMesh"
	multimesh.mesh = blatt_mesh.mesh.duplicate() # FIXME Warum ist duplicate notwendig?
	var blatt_transform: Transform = blatt_mesh.transform
	multimesh.instance_count = anzahl
	for i in  range(anzahl):
		var t1: Transform = Transform.IDENTITY
		t1 = t1.rotated(Vector3.UP, i * 2 * PI / anzahl).translated(Vector3(0, 0.3, 0))
		# TODO Rotation
		var t2: Transform = t1 * blatt_transform
		print("t1=",t1, " t2=", t2)
		multimesh.set_instance_transform(i, t2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
