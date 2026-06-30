class_name NPCShip
extends Node3D
# NPC-Schiff: oranger Wuerfel (siehe Referenz Abschnitt 5).

func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4, 2, 6)
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.55, 0.1)
	mesh_instance.material_override = mat
	add_child(mesh_instance)
