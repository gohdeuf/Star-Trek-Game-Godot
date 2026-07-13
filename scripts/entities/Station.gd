class_name Station
extends Node3D
func _ready() -> void:
	var mi := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(8, 8, 8); mi.mesh = bx
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.2, 0.4, 0.9)
	mi.material_override = mat; add_child(mi)
