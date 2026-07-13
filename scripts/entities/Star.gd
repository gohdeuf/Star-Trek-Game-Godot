class_name Star
extends Node3D
var system_name: String = ""
func _ready() -> void:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new(); sp.radius = 3.0; sp.height = 6.0; mi.mesh = sp
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(1.0, 0.9, 0.4)
	mat.emission_enabled = true; mat.emission = Color(1.0, 0.85, 0.3); mat.emission_energy_multiplier = 2.0
	mi.material_override = mat; add_child(mi)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.95, 0.8); l.omni_range = 1500.0; add_child(l)
func set_system_name(n: String) -> void: system_name = n; name = n.replace(" ", "_")
