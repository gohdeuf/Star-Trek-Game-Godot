class_name Station
extends Node3D

func _ready() -> void:
	add_to_group("stations")
	var mi := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(8, 8, 8); mi.mesh = bx
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.9)
	mat.metallic = 0.7; mat.roughness = 0.2
	mi.material_override = mat; add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.6, 1.0)
	light.omni_range = 35.0; light.light_energy = 1.5
	add_child(light)
