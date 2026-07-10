class_name PlayerActions
extends Node
# Einfache Basis-Version fuer Bau-/Abbau-Gameplay (siehe README "Bewusste
# Vereinfachungen"). Zwei Aktionen:
#
#   - "build_station" (Taste B): platziert sofort eine Station an der
#     aktuellen Schiffsposition im aktuellen Sektor und persistiert sie
#     ueber GameDatabase.add_station().
#   - "mine_resource" (Taste M, gehalten): baut kontinuierlich Ressourcen
#     vom naechstgelegenen Planeten in Reichweite ab (siehe MINING_RANGE/
#     MINING_RATE) und persistiert den Fortschritt periodisch ueber
#     GameDatabase.update_planet_resource().
#
# Bewusst simpel gehalten (auf Wunsch als erste Basis-Version): kein
# Baukosten-/Inventarsystem, keine Abbauwerkzeuge/-level, keine Kollisions-
# pruefung beim Bauen. Naechster moeglicher Ausbauschritt.

const MINING_RANGE := 20.0   # zusaetzlich zum Planetenradius
const MINING_RATE := 80.0    # Ressourceneinheiten pro Sekunde
const PERSIST_INTERVAL := 1.0

var ship: Node3D
var world_manager: WorldManager
var hud: SOINotification
var station_scene: PackedScene = preload("res://scenes/Station.tscn")

var _mining_planet: Planet = null
var _persist_timer: float = 0.0

func setup(p_ship: Node3D, p_world_manager: WorldManager, p_hud: SOINotification) -> void:
	ship = p_ship
	world_manager = p_world_manager
	hud = p_hud

func _process(delta: float) -> void:
	if ship == null:
		return
	_handle_mining(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_station"):
		_build_station()

# --- Bauen ---

func _build_station() -> void:
	var coords := SectorUtils.world_to_sector_coords(ship.global_position)
	var sector_id := SectorUtils.sector_coords_to_id(coords.x, coords.y, coords.z)

	var station := station_scene.instantiate()
	var container := world_manager.get_sector_container(sector_id)
	if container != null:
		container.add_child(station)
	else:
		# Sollte praktisch nicht vorkommen (Schiff steht ja im aktuell
		# geladenen Sektor), aber sicherheitshalber ein Fallback.
		add_child(station)
	station.global_position = ship.global_position

	GameDatabase.add_station(sector_id, {
		"pos_x": ship.global_position.x,
		"pos_y": ship.global_position.y,
		"pos_z": ship.global_position.z,
	})

	if hud != null:
		hud.show_message(Locale.t("actions.station_built"))

# --- Abbauen ---

func _handle_mining(delta: float) -> void:
	if _mining_planet != null and not is_instance_valid(_mining_planet):
		_mining_planet = null

	var nearby := _find_nearby_planet()

	if not Input.is_action_pressed("mine_resource") or nearby == null:
		if _mining_planet != null:
			_persist_mining(_mining_planet)
			_mining_planet = null
		return

	_mining_planet = nearby
	var resources: Dictionary = _mining_planet.planet_data["resources"]
	var current: float = resources["current"]
	var planet_name: String = _mining_planet.planet_data["name"]

	if current <= 0.0:
		if hud != null:
			hud.show_message(Locale.t("actions.mine_empty", {"planet": planet_name}))
		return

	current = max(0.0, current - MINING_RATE * delta)
	resources["current"] = current

	if hud != null:
		hud.show_message(Locale.t("actions.mining", {
			"planet": planet_name,
			"amount": str(int(current)),
		}))

	_persist_timer += delta
	if _persist_timer >= PERSIST_INTERVAL:
		_persist_timer = 0.0
		_persist_mining(_mining_planet)

func _persist_mining(planet: Planet) -> void:
	var coords := SectorUtils.world_to_sector_coords(planet.global_position)
	var sector_id := SectorUtils.sector_coords_to_id(coords.x, coords.y, coords.z)
	GameDatabase.update_planet_resource(sector_id, planet.planet_data["name"], planet.planet_data["resources"]["current"])

func _find_nearby_planet() -> Planet:
	var best: Planet = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("planets"):
		var planet := node as Planet
		if planet == null:
			continue
		var planet_radius: float = planet.planet_data.get("radius", 0.0)
		var dist: float = ship.global_position.distance_to(planet.global_position) - planet_radius
		if dist <= MINING_RANGE and dist < best_dist:
			best = planet
			best_dist = dist
	return best
