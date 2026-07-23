class_name Moon
extends Node3D

var parent_planet:     Node3D = null
var orbit_radius:      float  = 5.0
var moon_display_name: String = ""
var moon_radius:       float  = 0.8   # Echte Mondgröße aus Daten

var _angle_deg: float = 0.0
var _speed_deg: float = 20.0

func _ready() -> void:
	add_to_group("moons")

func setup(parent: Node3D, orb: float, speed: float = 20.0, radius: float = 0.8) -> void:
	parent_planet = parent
	orbit_radius  = orb
	_speed_deg    = speed
	moon_radius   = radius

	var mi  := MeshInstance3D.new()
	var sp  := SphereMesh.new()
	sp.radius = moon_radius; sp.height = moon_radius * 2.0; mi.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.60, 0.60, 0.62)
	mi.material_override = mat
	add_child(mi)

func _process(delta: float) -> void:
	if parent_planet == null or not is_instance_valid(parent_planet): return
	_angle_deg = fmod(_angle_deg + _speed_deg * delta, 360.0)
	var rad := deg_to_rad(_angle_deg)
	global_position = parent_planet.global_position \
		+ Vector3(cos(rad) * orbit_radius, 0.0, sin(rad) * orbit_radius)