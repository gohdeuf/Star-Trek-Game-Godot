class_name PlayerActions
extends Node
# Bau-/Abbau-Gameplay.
#
# STATIONEN BAUEN (Taste B):
#   Kosten: STATION_COST_MINERALS Mineralien + STATION_COST_DEUTERIUM Deuterium.
#   Fehlen Ressourcen, erscheint eine HUD-Meldung; keine Station wird gebaut.
#
# RESSOURCEN ABBAUEN (Taste M, gehalten):
#   Baut gleichzeitig Mineralien (aus "resources") und Deuterium ab.
#   Abbaurate Deuterium: Gesteinsplanet = 20/s, Gasriese = 60/s.
#   Gewonnene Ressourcen gehen direkt ins GameDatabase.player_inventory.

const MINING_RANGE := 20.0

const MINING_RATE_MINERALS       := 80.0
const MINING_RATE_DEUTERIUM_ROCKY := 20.0
const MINING_RATE_DEUTERIUM_GAS   := 60.0

const PERSIST_INTERVAL  := 1.0   # Sekunden zwischen Disk-Schreibvorgaengen
const HUD_MSG_INTERVAL  := 0.3   # Sekunden zwischen HUD-Aktualisierungen

const STATION_COST_MINERALS  := 500
const STATION_COST_DEUTERIUM := 100

var ship: Node3D
var world_manager: WorldManager
var hud: SOINotification
var station_scene: PackedScene = preload("res://scenes/Station.tscn")

var _mining_planet: Planet = null
var _persist_timer: float  = 0.0
var _hud_timer:     float  = 0.0

func setup(p_ship: Node3D, p_world_manager: WorldManager, p_hud: SOINotification) -> void:
	ship          = p_ship
	world_manager = p_world_manager
	hud           = p_hud

func _process(delta: float) -> void:
	if ship == null:
		return
	_handle_mining(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_station"):
		_build_station()

# ---------------------------------------------------------------------------
# Bauen
# ---------------------------------------------------------------------------

func _build_station() -> void:
	# Ressourcen pruefen
	var have_min := GameDatabase.get_resource("minerals")
	var have_deu := GameDatabase.get_resource("deuterium")

	if have_min < STATION_COST_MINERALS:
		if hud != null:
			hud.show_message(Locale.t("actions.not_enough_minerals", {
				"cost": STATION_COST_MINERALS, "have": have_min,
			}))
		return

	if have_deu < STATION_COST_DEUTERIUM:
		if hud != null:
			hud.show_message(Locale.t("actions.not_enough_deuterium", {
				"cost": STATION_COST_DEUTERIUM, "have": have_deu,
			}))
		return

	# Ressourcen abziehen
	GameDatabase.spend_resource("minerals",  STATION_COST_MINERALS)
	GameDatabase.spend_resource("deuterium", STATION_COST_DEUTERIUM)

	# Station platzieren
	var coords    := SectorUtils.world_to_sector_coords(ship.global_position)
	var sector_id := SectorUtils.sector_coords_to_id(coords.x, coords.y, coords.z)

	var station := station_scene.instantiate()
	var container := world_manager.get_sector_container(sector_id)
	if container != null:
		container.add_child(station)
	else:
		add_child(station)
	station.global_position = ship.global_position

	GameDatabase.add_station(sector_id, {
		"pos_x": ship.global_position.x,
		"pos_y": ship.global_position.y,
		"pos_z": ship.global_position.z,
	})

	if hud != null:
		hud.show_message(Locale.t("actions.station_built"))

# ---------------------------------------------------------------------------
# Abbauen
# ---------------------------------------------------------------------------

func _handle_mining(delta: float) -> void:
	_hud_timer    += delta
	_persist_timer += delta

	# Instanzvalidierung
	if _mining_planet != null and not is_instance_valid(_mining_planet):
		_mining_planet = null

	var nearby := _find_nearby_planet()

	# Taste losgelassen oder kein Planet in Reichweite
	if not Input.is_action_pressed("mine_resource") or nearby == null:
		if _mining_planet != null:
			_persist_mining(_mining_planet)
			_mining_planet = null
		return

	_mining_planet = nearby
	var cls: String  = _mining_planet.planet_data["class"]
	var is_gas: bool = PlanetClassDB.classes[cls]["type"] == "gas"
	var deu_rate := MINING_RATE_DEUTERIUM_GAS if is_gas else MINING_RATE_DEUTERIUM_ROCKY

	# --- Mineralien ---
	var resources: Dictionary = _mining_planet.planet_data["resources"]
	var minerals_mined := 0.0
	if resources["current"] > 0.0:
		minerals_mined = min(MINING_RATE_MINERALS * delta, resources["current"])
		resources["current"] = max(0.0, resources["current"] - minerals_mined)
		GameDatabase.add_resource("minerals", minerals_mined)

	# --- Deuterium ---
	var deuterium_mined := 0.0
	if _mining_planet.planet_data.has("deuterium"):
		var deu: Dictionary = _mining_planet.planet_data["deuterium"]
		if deu["current"] > 0.0:
			deuterium_mined = min(deu_rate * delta, deu["current"])
			deu["current"] = max(0.0, deu["current"] - deuterium_mined)
			GameDatabase.add_resource("deuterium", deuterium_mined)

	# HUD-Nachricht (gedrosselt auf HUD_MSG_INTERVAL)
	if hud != null and _hud_timer >= HUD_MSG_INTERVAL:
		_hud_timer = 0.0
		var planet_name: String = _mining_planet.planet_data["name"]
		var min_remain := int(_mining_planet.planet_data["resources"]["current"])
		var deu_remain := int(_mining_planet.planet_data.get("deuterium", {}).get("current", 0.0))

		if min_remain == 0 and deu_remain == 0:
			hud.show_message(Locale.t("actions.mine_empty", {"planet": planet_name}))
		else:
			hud.show_message(Locale.t("actions.mining", {
				"planet":    planet_name,
				"minerals":  min_remain,
				"deuterium": deu_remain,
			}))

	# Periodisch auf Disk schreiben
	if _persist_timer >= PERSIST_INTERVAL:
		_persist_timer = 0.0
		_persist_mining(_mining_planet)

func _persist_mining(planet: Planet) -> void:
	var coords    := SectorUtils.world_to_sector_coords(planet.global_position)
	var sector_id := SectorUtils.sector_coords_to_id(coords.x, coords.y, coords.z)
	GameDatabase.save_planet_state(
		sector_id,
		planet.planet_data["name"],
		planet.planet_data["resources"]["current"],
		planet.planet_data.get("deuterium", {}).get("current", 0.0)
	)

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
