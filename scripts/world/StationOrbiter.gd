class_name StationOrbiter
extends Node3D

# Unsichtbarer Orbitalanker – alle Stationsparts sind Kinder dieses Nodes.
# Bewegt sich in _process() → Children folgen automatisch.

var orbit_id:       String  = ""
var planet_node:    Node3D  = null
var orbit_radius:   float   = 50.0
var orbit_angle_deg: float  = 0.0   # öffentlich – WorldManager liest/schreibt
var _orbit_speed_deg: float = 0.2

func _ready() -> void:
	add_to_group("station_orbiters")

func setup(planet: Node3D, radius: float, angle_deg: float, speed_deg: float) -> void:
	planet_node      = planet
	orbit_radius     = radius
	orbit_angle_deg  = angle_deg
	_orbit_speed_deg = speed_deg
	_apply_position()

func _process(delta: float) -> void:
	if planet_node == null or not is_instance_valid(planet_node): return
	orbit_angle_deg = fmod(orbit_angle_deg + _orbit_speed_deg * delta, 360.0)
	_apply_position()

func _apply_position() -> void:
	if planet_node == null: return
	var rad: float  = deg_to_rad(orbit_angle_deg)
	global_position = planet_node.global_position \
		+ Vector3(cos(rad) * orbit_radius, 0.0, sin(rad) * orbit_radius)