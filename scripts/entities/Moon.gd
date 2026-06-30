class_name Moon
extends Node3D
# Mond: umkreist einen Elternplaneten auf Kreisbahn in der XZ-Ebene
# (siehe Referenz Abschnitt 7). Aktuell als wiederverwendbare Komponente
# vorbereitet; die automatische Zuordnung "welcher Planet bekommt einen
# Mond" ist noch nicht in SectorGenerator verdrahtet (naechster Ausbauschritt).

var parent_planet: Node3D
var orbit_radius: float = 5.0
var _angle_deg: float = 0.0
var _angular_speed_deg: float = 20.0

func setup(parent: Node3D, p_orbit_radius: float, p_angular_speed_deg: float = 20.0) -> void:
	parent_planet = parent
	orbit_radius = p_orbit_radius
	_angular_speed_deg = p_angular_speed_deg

	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.2
	sphere.height = 2.4
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _process(delta: float) -> void:
	if parent_planet == null:
		return
	_angle_deg += _angular_speed_deg * delta
	var rad := deg_to_rad(_angle_deg)
	var offset := Vector3(cos(rad) * orbit_radius, 0.0, sin(rad) * orbit_radius)
	global_position = parent_planet.global_position + offset
