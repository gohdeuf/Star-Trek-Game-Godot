class_name PlayerActions
extends Node
# Bau- und Abbau-Gameplay.
# B   = Haupt-Stationsmodul (500 Min + 100 Deu)
# 2   = FusionCore            (300 Min +  50 Deu)
# 3   = AM-Fabrik Klein       (200 Min + 100 Deu)
# 4   = AM-Fabrik Gross       (600 Min + 200 Deu)
# M   = Abbauen

const MINING_RANGE := 20.0
const MINING_RATE_MINERALS        := 80.0
const MINING_RATE_DEUTERIUM_ROCKY := 20.0
const MINING_RATE_DEUTERIUM_GAS   := 60.0
const PERSIST_INTERVAL := 1.0
const HUD_MSG_INTERVAL := 0.3

# Baukosten [minerals, deuterium]
const COSTS := {
	"main_station":    [500, 100],
	"fusion_core":     [300,  50],
	"am_factory_small":[200, 100],
	"am_factory_big":  [600, 200],
}

var ship: Node3D; var world_manager: WorldManager; var hud: SOINotification
var _part_scenes: Dictionary = {}
var _mining_planet: Planet = null
var _persist_timer: float = 0.0; var _hud_timer: float = 0.0

func setup(p_ship: Node3D, p_world_manager: WorldManager, p_hud: SOINotification) -> void:
	ship = p_ship; world_manager = p_world_manager; hud = p_hud
	_part_scenes = {
		"main_station":     preload("res://scenes/station_parts/MainStationPart.tscn"),
		"fusion_core":      preload("res://scenes/station_parts/FusionCore.tscn"),
		"am_factory_small": preload("res://scenes/station_parts/AntimatterFactorySmall.tscn"),
		"am_factory_big":   preload("res://scenes/station_parts/AntimatterFactoryBig.tscn"),
	}

func _process(delta: float) -> void:
	if ship == null: return
	_handle_mining(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_station"):   _build_part("main_station")
	if event.is_action_pressed("build_fusion"):    _build_part("fusion_core")
	if event.is_action_pressed("build_am_small"):  _build_part("am_factory_small")
	if event.is_action_pressed("build_am_big"):    _build_part("am_factory_big")

func _build_part(part_type: String) -> void:
	var costs: Array = COSTS[part_type]
	var cost_min: int = costs[0]; var cost_deu: int = costs[1]
	var have_min := GameDatabase.get_resource("minerals")
	var have_deu := GameDatabase.get_resource("deuterium")
	if have_min < cost_min:
		if hud: hud.show_message(Locale.t("actions.not_enough_minerals",{"cost":cost_min,"have":have_min}))
		return
	if have_deu < cost_deu:
		if hud: hud.show_message(Locale.t("actions.not_enough_deuterium",{"cost":cost_deu,"have":have_deu}))
		return
	GameDatabase.spend_resource("minerals",  cost_min)
	GameDatabase.spend_resource("deuterium", cost_deu)
	var coords    := SectorUtils.world_to_sector_coords(ship.global_position)
	var sector_id := SectorUtils.sector_coords_to_id(coords.x, coords.y, coords.z)
	var inst: Node3D = _part_scenes[part_type].instantiate()
	var container := world_manager.get_sector_container(sector_id)
	if container != null: container.add_child(inst)
	else: add_child(inst)
	inst.global_position = ship.global_position
	GameDatabase.add_station(sector_id, {
		"pos_x": ship.global_position.x,
		"pos_y": ship.global_position.y,
		"pos_z": ship.global_position.z,
		"type":  part_type,
	})
	if hud: hud.show_message(Locale.t("actions.part_built", {"part": Locale.t("part." + part_type)}))

func _handle_mining(delta: float) -> void:
	_hud_timer += delta; _persist_timer += delta
	if _mining_planet != null and not is_instance_valid(_mining_planet): _mining_planet = null
	var nearby := _find_nearby_planet()
	if not Input.is_action_pressed("mine_resource") or nearby == null:
		if _mining_planet != null: _persist_mining(_mining_planet); _mining_planet = null
		return
	_mining_planet = nearby
	var cls: String  = _mining_planet.planet_data["class"]
	var is_gas: bool = PlanetClassDB.classes[cls]["type"] == "gas"
	var deu_rate := MINING_RATE_DEUTERIUM_GAS if is_gas else MINING_RATE_DEUTERIUM_ROCKY
	var resources: Dictionary = _mining_planet.planet_data["resources"]
	var minerals_mined := 0.0
	if resources["current"] > 0.0:
		minerals_mined = min(MINING_RATE_MINERALS * delta, resources["current"])
		resources["current"] = max(0.0, resources["current"] - minerals_mined)
		GameDatabase.add_resource("minerals", minerals_mined)
	var deuterium_mined := 0.0
	if _mining_planet.planet_data.has("deuterium"):
		var deu: Dictionary = _mining_planet.planet_data["deuterium"]
		if deu["current"] > 0.0:
			deuterium_mined = min(deu_rate * delta, deu["current"])
			deu["current"] = max(0.0, deu["current"] - deuterium_mined)
			GameDatabase.add_resource("deuterium", deuterium_mined)
	if hud != null and _hud_timer >= HUD_MSG_INTERVAL:
		_hud_timer = 0.0
		var planet_name: String = _mining_planet.planet_data["name"]
		var min_remain := int(_mining_planet.planet_data["resources"]["current"])
		var deu_remain := int(_mining_planet.planet_data.get("deuterium",{}).get("current",0.0))
		if min_remain == 0 and deu_remain == 0:
			hud.show_message(Locale.t("actions.mine_empty",{"planet":planet_name}))
		else:
			hud.show_message(Locale.t("actions.mining",{"planet":planet_name,"minerals":min_remain,"deuterium":deu_remain}))
	if _persist_timer >= PERSIST_INTERVAL: _persist_timer = 0.0; _persist_mining(_mining_planet)

func _persist_mining(planet: Planet) -> void:
	var coords    := SectorUtils.world_to_sector_coords(planet.global_position)
	var sector_id := SectorUtils.sector_coords_to_id(coords.x, coords.y, coords.z)
	GameDatabase.save_planet_state(sector_id, planet.planet_data["name"],
		planet.planet_data["resources"]["current"],
		planet.planet_data.get("deuterium",{}).get("current",0.0))

func _find_nearby_planet() -> Planet:
	var best: Planet = null; var best_dist := INF
	for node in get_tree().get_nodes_in_group("planets"):
		var planet := node as Planet
		if planet == null: continue
		var planet_radius: float = planet.planet_data.get("radius", 0.0)
		var dist: float = ship.global_position.distance_to(planet.global_position) - planet_radius
		if dist <= MINING_RANGE and dist < best_dist: best = planet; best_dist = dist
	return best
