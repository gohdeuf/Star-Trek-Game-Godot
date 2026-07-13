class_name SOITracker
extends Node
signal enter_system(system_data: Dictionary)
signal exit_system(system_data: Dictionary)
enum FlightState { INTERSTELLAR, SYSTEM }
var state: int = FlightState.INTERSTELLAR; var active_system: Dictionary = {}; var player: Node3D
func set_player(node: Node3D) -> void: player = node
func _process(_delta: float) -> void:
	if player == null: return
	var found := find_active_system(player.global_position)
	if found.is_empty():
		if state == FlightState.SYSTEM:
			state = FlightState.INTERSTELLAR; exit_system.emit(active_system); active_system = {}
	else:
		if active_system.get("system_id", "") != found.get("system_id", ""):
			if state == FlightState.SYSTEM: exit_system.emit(active_system)
			active_system = found; state = FlightState.SYSTEM; enter_system.emit(active_system)
func find_active_system(ship_pos: Vector3) -> Dictionary:
	var best: Dictionary = {}; var best_dist := INF
	for sys in SectorGenerator.get_cached_systems():
		var d := SectorUtils.distance_3d(ship_pos, sys["position"])
		if d <= sys["sphere_of_influence"] and d < best_dist: best = sys; best_dist = d
	return best
