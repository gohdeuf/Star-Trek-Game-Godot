class_name SOITracker
extends Node
# Sphere-of-Influence-Tracking (siehe Referenz Abschnitt 4).
# Zustandsmaschine INTERSTELLAR <-> SYSTEM mit Enter/Exit-Signalen.

signal enter_system(system_data: Dictionary)
signal exit_system(system_data: Dictionary)

enum FlightState { INTERSTELLAR, SYSTEM }

var state: int = FlightState.INTERSTELLAR
var active_system: Dictionary = {}
var player: Node3D

func set_player(node: Node3D) -> void:
	player = node

func _process(_delta: float) -> void:
	if player == null:
		return
	var found := find_active_system(player.global_position)
	if found.is_empty():
		if state == FlightState.SYSTEM:
			state = FlightState.INTERSTELLAR
			exit_system.emit(active_system)
			active_system = {}
	else:
		if active_system.get("system_id", "") != found.get("system_id", ""):
			if state == FlightState.SYSTEM:
				exit_system.emit(active_system)
			active_system = found
			state = FlightState.SYSTEM
			enter_system.emit(active_system)

## Prueft, ob das Schiff innerhalb der SOI eines geladenen Systems ist;
## bei Ueberlappung wird das naechstgelegene System gewaehlt.
func find_active_system(ship_pos: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := INF
	for sys in SectorGenerator.get_cached_systems():
		var d := SectorUtils.distance_3d(ship_pos, sys["position"])
		if d <= sys["sphere_of_influence"] and d < best_dist:
			best = sys
			best_dist = d
	return best

static func world_to_system_relative(world_pos: Vector3, system_origin: Vector3) -> Vector3:
	return world_pos - system_origin

static func system_relative_to_world(rel_pos: Vector3, system_origin: Vector3) -> Vector3:
	return rel_pos + system_origin
