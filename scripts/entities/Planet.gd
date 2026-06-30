class_name Planet
extends Node3D
# Planet: Star-Trek-Klassifizierung D/H/K/L/M/N/Y (fest) bzw. J/T/6/7/9
# (Gasriesen), siehe Referenz Abschnitt 7. Position/Klasse/Radius/Ressourcen
# kommen vollstaendig aus dem (world-seed-deterministischen) SectorGenerator.

var planet_data: Dictionary = {}
var star_node: Node3D
const ROTATION_SPEED_DEG := 10.0  # Y-Achsen-Eigenrotation, 10 Grad/s

func setup(data: Dictionary, star: Node3D) -> void:
	planet_data = data
	star_node = star

	var cls: String = data["class"]
	var cls_data: Dictionary = PlanetClassDB.classes[cls]
	var planet_radius: float = data["radius"]

	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = planet_radius
	sphere.height = planet_radius * 2.0
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cls_data["color"]
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	name = String(data["name"]).replace(" ", "_")
	_update_orbit_position()

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(ROTATION_SPEED_DEG * delta))

func _update_orbit_position() -> void:
	if star_node == null:
		return
	var rad := deg_to_rad(float(planet_data["orbit_angle"]))
	var orbit_radius: float = planet_data["orbit_radius"]
	var offset := Vector3(cos(rad) * orbit_radius, 0.0, sin(rad) * orbit_radius)
	global_position = star_node.global_position + offset
