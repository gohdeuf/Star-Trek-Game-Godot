extends Node
const SAVE_DIR    := "user://savegame/"
const META_FILE   := SAVE_DIR + "world_meta.json"
const SECTORS_DIR := SAVE_DIR + "sectors/"

var world_seed:       int        = 0
var player_position:  Vector3    = Vector3.ZERO
var player_rotation:  Quaternion = Quaternion.IDENTITY
var player_inventory: Dictionary = {"minerals":0.0,"deuterium":0.0,"antimatter":50.0}
var needs_seed_setup: bool   = false
var is_docked:        bool   = false
var docked_sector_id: String = ""
var docked_position:  Vector3 = Vector3.ZERO
var station_storage:  Dictionary = {}

func _ready() -> void:
	_ensure_save_dirs(); _load_or_create_world_meta()

func _ensure_save_dirs() -> void:
	var dir := DirAccess.open("user://")
	if dir != null: dir.make_dir_recursive("savegame/sectors")

func _load_or_create_world_meta() -> void:
	if not FileAccess.file_exists(META_FILE): needs_seed_setup = true; return
	var f := FileAccess.open(META_FILE, FileAccess.READ)
	if f == null: needs_seed_setup = true; return
	var text := f.get_as_text(); f.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary): needs_seed_setup = true; return
	var data: Dictionary = parsed
	if not data.has("world_seed"): needs_seed_setup = true; return
	world_seed       = _parse_seed_value(data["world_seed"])
	var p: Dictionary = data.get("player_position",{"x":0.0,"y":0.0,"z":0.0})
	player_position  = Vector3(p.get("x",0.0),p.get("y",0.0),p.get("z",0.0))
	var r: Dictionary = data.get("player_rotation",{"x":0.0,"y":0.0,"z":0.0,"w":1.0})
	player_rotation  = Quaternion(r.get("x",0.0),r.get("y",0.0),r.get("z",0.0),r.get("w",1.0))
	var inv: Dictionary = data.get("player_inventory",{"minerals":0.0,"deuterium":0.0,"antimatter":50.0})
	player_inventory = {
		"minerals":   float(inv.get("minerals",   0.0)),
		"deuterium":  float(inv.get("deuterium",  0.0)),
		"antimatter": float(inv.get("antimatter", 50.0)),
	}
	is_docked        = bool(data.get("is_docked", false))
	docked_sector_id = str(data.get("docked_sector_id", ""))
	var dp: Dictionary = data.get("docked_position",{"x":0.0,"y":0.0,"z":0.0})
	docked_position  = Vector3(dp.get("x",0.0),dp.get("y",0.0),dp.get("z",0.0))
	var ss: Variant    = data.get("station_storage", {})
	station_storage  = ss if ss is Dictionary else {}
	needs_seed_setup = false

func _parse_seed_value(raw: Variant) -> int:
	if raw is String: return (raw as String).to_int()
	return int(raw)

func _generate_random_seed() -> int:
	randomize(); var high: int = randi(); var low: int = randi()
	return (high << 32) | low

func finish_new_world_setup(custom_seed_text: String = "") -> void:
	if custom_seed_text.strip_edges() != "":
		set_world_seed_from_text(custom_seed_text.strip_edges())
	else:
		world_seed = _generate_random_seed(); save_world_meta()
	needs_seed_setup = false

func set_world_seed_from_text(text: String) -> void:
	var sha := text.sha256_buffer(); var seed_int: int = 0
	for i in range(8): seed_int = (seed_int << 8) | sha[i]
	world_seed = seed_int; save_world_meta()

func set_docked_state(docked: bool, sector_id: String, pos: Vector3) -> void:
	is_docked = docked; docked_sector_id = sector_id; docked_position = pos
	save_world_meta()

func save_world_meta() -> void:
	var data := {
		"world_seed":       str(world_seed),
		"player_position":  {"x":player_position.x,  "y":player_position.y,  "z":player_position.z},
		"player_rotation":  {"x":player_rotation.x,  "y":player_rotation.y,  "z":player_rotation.z, "w":player_rotation.w},
		"player_inventory": player_inventory,
		"is_docked":        is_docked,
		"docked_sector_id": docked_sector_id,
		"docked_position":  {"x":docked_position.x,  "y":docked_position.y,  "z":docked_position.z},
		"station_storage":  station_storage,
	}
	var f := FileAccess.open(META_FILE, FileAccess.WRITE)
	if f == null: push_error("GameDatabase: world_meta.json nicht schreibbar"); return
	f.store_string(JSON.stringify(data, "  ")); f.close()

func save_player_state(pos: Vector3, rot: Quaternion) -> void:
	player_position = pos; player_rotation = rot; save_world_meta()

# ── Spieler-Inventar ──────────────────────────────────────────────────────────
func get_resource(type: String) -> int:
	return int(player_inventory.get(type, 0.0))

func add_resource(type: String, amount: float) -> void:
	player_inventory[type] = float(player_inventory.get(type, 0.0)) + amount

func spend_resource(type: String, amount: int) -> bool:
	var current: float = float(player_inventory.get(type, 0.0))
	if int(current) < amount: return false
	player_inventory[type] = current - float(amount); return true

# ── Stations-Ressourcen (lokal, unabhängig vom Spieler-Inventar) ──────────────
func get_station_resource(sid: String, type: String) -> int:
	return int(float(get_station_storage(sid).get(type, 0.0)))

func add_station_resource(sid: String, type: String, amount: float) -> void:
	var st := get_station_storage(sid)
	st[type] = float(st.get(type, 0.0)) + amount
	station_storage[sid] = st   # kein save_world_meta() hier – Spar-Zyklus reicht

func spend_station_resource(sid: String, type: String, amount: float) -> bool:
	var st := get_station_storage(sid)
	var current: float = float(st.get(type, 0.0))
	if current < amount: return false
	st[type] = current - amount
	station_storage[sid] = st
	return true

# ── Stations-Lager ────────────────────────────────────────────────────────────
func get_station_id(hub_pos: Vector3) -> String:
	return "station_%d_%d_%d" % [int(round(hub_pos.x)), int(round(hub_pos.y)), int(round(hub_pos.z))]

func get_station_storage(sid: String) -> Dictionary:
	if not station_storage.has(sid):
		station_storage[sid] = {"minerals":0.0,"deuterium":0.0,"antimatter":0.0}
	return station_storage[sid]

func deposit_to_station(sid: String, cap_min: int, cap_deu: int, cap_am: int) -> void:
	var st := get_station_storage(sid)
	var space_min: int = cap_min - int(st.get("minerals",  0.0))
	var space_deu: int = cap_deu - int(st.get("deuterium", 0.0))
	var space_am:  int = cap_am  - int(st.get("antimatter",0.0))
	var move_min: int = min(get_resource("minerals"),  max(0, space_min))
	var move_deu: int = min(get_resource("deuterium"), max(0, space_deu))
	var move_am:  int = min(get_resource("antimatter"),max(0, space_am))
	if move_min > 0: spend_resource("minerals",  move_min); st["minerals"]   = float(st.get("minerals",  0.0)) + move_min
	if move_deu > 0: spend_resource("deuterium", move_deu); st["deuterium"]  = float(st.get("deuterium", 0.0)) + move_deu
	if move_am  > 0: spend_resource("antimatter",move_am);  st["antimatter"] = float(st.get("antimatter",0.0)) + move_am
	station_storage[sid] = st; save_world_meta()

func withdraw_from_station(sid: String) -> void:
	var st := get_station_storage(sid)
	add_resource("minerals",  float(int(st.get("minerals",  0.0))))
	add_resource("deuterium", float(int(st.get("deuterium", 0.0))))
	add_resource("antimatter",float(int(st.get("antimatter",0.0))))
	st["minerals"] = 0.0; st["deuterium"] = 0.0; st["antimatter"] = 0.0
	station_storage[sid] = st; save_world_meta()

# ── Orbitalstationen ──────────────────────────────────────────────────────────
func create_orbital_station(sector_id: String, orbit_id: String, planet_name: String,
		orbit_radius: float, orbit_angle_deg: float, orbit_speed_deg: float) -> void:
	var data := load_sector_data(sector_id)
	var orbital: Array = data.get("orbital_stations", [])
	orbital.append({
		"orbit_id": orbit_id, "planet_name": planet_name,
		"orbit_radius": orbit_radius, "orbit_angle_deg": orbit_angle_deg,
		"orbit_speed_deg": orbit_speed_deg, "parts": [],
	})
	data["orbital_stations"] = orbital; save_sector_data(sector_id, data)

func add_orbital_station_part(sector_id: String, orbit_id: String,
		part_type: String, offset: Vector3) -> void:
	var data := load_sector_data(sector_id)
	var orbital: Array = data.get("orbital_stations", [])
	for entry in orbital:
		if entry.get("orbit_id", "") != orbit_id: continue
		var parts: Array = entry.get("parts", [])
		parts.append({"type": part_type, "off_x": offset.x, "off_y": offset.y, "off_z": offset.z})
		entry["parts"] = parts; data["orbital_stations"] = orbital
		save_sector_data(sector_id, data); return

func save_orbital_station_angle(sector_id: String, orbit_id: String, angle_deg: float) -> void:
	var data := load_sector_data(sector_id)
	var orbital: Array = data.get("orbital_stations", [])
	for entry in orbital:
		if entry.get("orbit_id", "") != orbit_id: continue
		entry["orbit_angle_deg"] = angle_deg
		data["orbital_stations"] = orbital; save_sector_data(sector_id, data); return

# ── Sektor ────────────────────────────────────────────────────────────────────
func _sector_file(sector_id: String) -> String: return SECTORS_DIR + sector_id + ".json"

func load_sector_data(sector_id: String) -> Dictionary:
	var path := _sector_file(sector_id)
	if not FileAccess.file_exists(path): return {}
	var f := FileAccess.open(path, FileAccess.READ); if f == null: return {}
	var text := f.get_as_text(); f.close()
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}

func save_sector_data(sector_id: String, data: Dictionary) -> void:
	var f := FileAccess.open(_sector_file(sector_id), FileAccess.WRITE)
	if f == null: push_error("Sektordatei nicht schreibbar: %s" % sector_id); return
	f.store_string(JSON.stringify(data, "  ")); f.close()

func save_planet_state(sector_id: String, planet_name: String, minerals: float, deuterium: float) -> void:
	var data := load_sector_data(sector_id)
	var min_ov: Dictionary = data.get("planet_resources",{}); var deu_ov: Dictionary = data.get("planet_deuterium",{})
	min_ov[planet_name] = minerals; deu_ov[planet_name] = deuterium
	data["planet_resources"] = min_ov; data["planet_deuterium"] = deu_ov; save_sector_data(sector_id, data)

func add_station(sector_id: String, station: Dictionary) -> void:
	var data := load_sector_data(sector_id)
	var stations: Array = data.get("stations", []); stations.append(station)
	data["stations"] = stations; save_sector_data(sector_id, data)

func add_ship(sector_id: String, ship: Dictionary) -> void:
	var data := load_sector_data(sector_id)
	var ships: Array = data.get("ships", []); ships.append(ship)
	data["ships"] = ships; save_sector_data(sector_id, data)