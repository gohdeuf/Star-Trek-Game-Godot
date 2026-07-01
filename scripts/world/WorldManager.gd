class_name WorldManager
extends Node3D
# Chunk-Loading nach Spielerposition (siehe Referenz Abschnitt 5).
#
# Laeuft jeden Frame, bestimmt den aktuellen Sektor des Spielers, laedt bei
# Sektorwechsel den 3x3x3-Nachbarschaftsblock neu und entlaedt Sektoren,
# die nicht mehr im Block liegen.

var star_scene: PackedScene = preload("res://scenes/Star.tscn")
var planet_scene: PackedScene = preload("res://scenes/Planet.tscn")
var moon_scene: PackedScene = preload("res://scenes/Moon.tscn")
var station_scene: PackedScene = preload("res://scenes/Station.tscn")
var npc_ship_scene: PackedScene = preload("res://scenes/NPCShip.tscn")
const SECTOR_UTILS := preload("res://scripts/autoload/SectorUtils.gd")

var player: Node3D
var _current_sector_id: String = ""
var _loaded_sectors: Dictionary = {}  # sector_id -> Node3D (Container)

func set_player(node: Node3D) -> void:
	player = node

func _process(_delta: float) -> void:
	if player == null:
		return
	var coords := SECTOR_UTILS.world_to_sector_coords(player.global_position)
	var sector_id := SECTOR_UTILS.sector_coords_to_id(coords.x, coords.y, coords.z)
	if sector_id != _current_sector_id:
		_current_sector_id = sector_id
		_on_sector_changed(sector_id)

func _on_sector_changed(center_sector_id: String) -> void:
	var needed: Array = SECTOR_UTILS.neighbor_sector_ids(center_sector_id)
	var needed_set := {}
	for id in needed:
		needed_set[id] = true
		if not _loaded_sectors.has(id):
			_load_sector(id)

	var to_unload: Array = []
	for id in _loaded_sectors.keys():
		if not needed_set.has(id):
			to_unload.append(id)
	for id in to_unload:
		_unload_sector(id)

func _load_sector(sector_id: String) -> void:
	var container := Node3D.new()
	container.name = sector_id
	add_child(container)
	_loaded_sectors[sector_id] = container

	var system: Dictionary = SectorGenerator.ensure_sector_generated(sector_id)
	if system.is_empty():
		return

	var star := star_scene.instantiate()
	container.add_child(star)
	star.global_position = system["position"]
	star.set_system_name(system["name"])

	for planet_data in system["planets"]:
		var planet := planet_scene.instantiate()
		container.add_child(planet)
		planet.setup(planet_data, star)

		for moon_data in planet_data.get("moons", []):
			var moon := moon_scene.instantiate()
			container.add_child(moon)
			moon.name = String(moon_data["name"]).replace(" ", "_")
			moon.setup(planet, moon_data["orbit_radius"], moon_data["angular_speed_deg"])

	var sector_save := GameDatabase.load_sector_data(sector_id)
	for station_data in sector_save.get("stations", []):
		var st := station_scene.instantiate()
		container.add_child(st)
		st.global_position = Vector3(station_data.pos_x, station_data.pos_y, station_data.pos_z)

	for ship_data in sector_save.get("ships", []):
		var sh := npc_ship_scene.instantiate()
		container.add_child(sh)
		sh.global_position = Vector3(ship_data.pos_x, ship_data.pos_y, ship_data.pos_z)

func _unload_sector(sector_id: String) -> void:
	var container: Node3D = _loaded_sectors.get(sector_id)
	if container == null:
		return
	# TODO (folgender Ausbauschritt): Ressourcenstaende abgebauter Planeten
	# sowie vom Spieler gebaute Stationen/Schiffe ueber GameDatabase.update_planet_resource()
	# bzw. add_station()/add_ship() zurueckschreiben, sobald Bau-/Abbau-Gameplay existiert.
	container.queue_free()
	_loaded_sectors.erase(sector_id)
