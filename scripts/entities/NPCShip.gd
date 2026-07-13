class_name NPCShip
extends Node3D
func _ready() -> void:
	var mi := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(4, 2, 6); mi.mesh = bx
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.95, 0.55, 0.1)
	mi.material_override = mat; add_child(mi)
