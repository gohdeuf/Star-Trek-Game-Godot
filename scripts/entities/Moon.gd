class_name Moon
extends Node3D
var parent_planet: Node3D; var orbit_radius: float = 5.0
var _angle_deg: float = 0.0; var _speed_deg: float = 20.0
func setup(parent: Node3D, orb: float, speed: float = 20.0) -> void:
	parent_planet = parent; orbit_radius = orb; _speed_deg = speed
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new(); sp.radius = 1.2; sp.height = 2.4; mi.mesh = sp
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.6, 0.6, 0.6)
	mi.material_override = mat; add_child(mi)
func _process(delta: float) -> void:
	if parent_planet == null: return
	_angle_deg += _speed_deg * delta; var rad := deg_to_rad(_angle_deg)
	global_position = parent_planet.global_position + Vector3(cos(rad) * orbit_radius, 0.0, sin(rad) * orbit_radius)
