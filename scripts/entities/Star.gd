class_name Star
extends Node3D
# Stern: gelbe leuchtende Sphaere (siehe Referenz Abschnitt 5).

var system_name: String = ""

func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 3.0
	sphere.height = 6.0
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.3)
	mat.emission_energy_multiplier = 2.0
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.8)
	light.omni_range = 1500.0
	add_child(light)

func set_system_name(n: String) -> void:
	system_name = n
	name = n.replace(" ", "_")
