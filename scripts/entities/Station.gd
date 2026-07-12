class_name Station
extends Node3D

func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(8, 8, 8)
	mesh_instance.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.9)
	mesh_instance.material_override = mat
	add_child(mesh_instance)
