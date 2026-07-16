class_name WorldManager
extends Node3D

var star_scene:             PackedScene = preload("res://scenes/Star.tscn")
var planet_scene:           PackedScene = preload("res://scenes/Planet.tscn")
var moon_scene:             PackedScene = preload("res://scenes/Moon.tscn")
var station_scene:          PackedScene = preload("res://scenes/Station.tscn")
var main_station_scene:     PackedScene = preload("res://scenes/station_parts/MainStationPart.tscn")
var fusion_core_scene:      PackedScene = preload("res://scenes/station_parts/FusionCore.tscn")
var am_factory_small_scene: PackedScene = preload("res://scenes/station_parts/AntimatterFactorySmall.tscn")
var am_factory_big_scene:   PackedScene = preload("res://scenes/station_parts/AntimatterFactoryBig.tscn")
var npc_ship_scene:         PackedScene = preload("res://scenes/NPCShip.tscn")
const SECTOR_UTILS := preload("res://scripts/autoload/SectorUtils.gd")

var player: Node3D
var _current_sector_id: String = ""
var _loaded_sectors: Dictionary = {}

func set_player(node: Node3D) -> void: player = node

func get_sector_container(sector_id: String) -> Node3D:
	return _loaded_sectors.get(sector_id, null)

func _process(_delta: float) -> void:
	if player == null: return
	var coords: Vector3i  = SECTOR_UTILS.world_to_sector_coords(player.global_position)
	var sector_id: String = SECTOR_UTILS.sector_coords_to_id(coords.x, coords.y, coords.z)
	if sector_id != _current_sector_id:
		_current_sector_id = sector_id; _on_sector_changed(sector_id)

func _on_sector_changed(center_sector_id: String) -> void:
	var needed: Array = SECTOR_UTILS.neighbor_sector_ids(center_sector_id)
	var needed_set := {}
	for id in needed:
		needed_set[id] = true
		if not _loaded_sectors.has(id): _load_sector(id)
	var to_unload: Array = []
	for id in _loaded_sectors.keys():
		if not needed_set.has(id): to_unload.append(id)
	for id in to_unload: _unload_sector(id)

func _load_sector(sector_id: String) -> void:
	var container := Node3D.new(); container.name = sector_id
	add_child(container); _loaded_sectors[sector_id] = container
	var system: Dictionary = SectorGenerator.ensure_sector_generated(sector_id)
	if system.is_empty(): return
	var star := star_scene.instantiate(); container.add_child(star)
	star.global_position = system["position"]; star.set_system_name(system["name"])
	for pd in system["planets"]:
		var planet := planet_scene.instantiate(); container.add_child(planet); planet.setup(pd, star)
		for md in pd.get("moons", []):
			var moon := moon_scene.instantiate(); container.add_child(moon)
			moon.name = String(md["name"]).replace(" ","_")
			moon.setup(planet, md["orbit_radius"], md["angular_speed_deg"])
	var sector_save := GameDatabase.load_sector_data(sector_id)
	for sd in sector_save.get("stations", []):
		var inst: Node3D = _instantiate_station_part(sd.get("type", "station"))
		container.add_child(inst)
		inst.global_position = Vector3(float(sd.get("pos_x",0)), float(sd.get("pos_y",0)), float(sd.get("pos_z",0)))
	for sh in sector_save.get("ships", []):
		var npc := npc_ship_scene.instantiate(); container.add_child(npc)
		npc.global_position = Vector3(float(sh.get("pos_x",0)), float(sh.get("pos_y",0)), float(sh.get("pos_z",0)))

func _instantiate_station_part(part_type: String) -> Node3D:
	match part_type:
		"main_station":    return main_station_scene.instantiate()
		"fusion_core":     return fusion_core_scene.instantiate()
		"am_factory_small": return am_factory_small_scene.instantiate()
		"am_factory_big":  return am_factory_big_scene.instantiate()
		_:                 return station_scene.instantiate()  # Legacy

func _unload_sector(sector_id: String) -> void:
	var container: Node3D = _loaded_sectors.get(sector_id)
	if container == null: return
	_save_sector_planet_resources(sector_id, container)
	container.queue_free(); _loaded_sectors.erase(sector_id)

func _save_sector_planet_resources(sector_id: String, container: Node3D) -> void:
	for child in container.get_children():
		if not child is Planet: continue
		var planet: Planet = child as Planet
		GameDatabase.save_planet_state(sector_id, planet.planet_data["name"],
			planet.planet_data["resources"]["current"],
			planet.planet_data.get("deuterium", {}).get("current", 0.0))

func save_all_sector_resources() -> void:
	for sector_id in _loaded_sectors.keys():
		var container: Node3D = _loaded_sectors[sector_id]
		if container != null: _save_sector_planet_resources(sector_id, container)
