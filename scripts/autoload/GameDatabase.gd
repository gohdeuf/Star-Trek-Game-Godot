extends Node
# Autoload: GameDatabase
# Variant-sicher: ueberall explizite Typen oder 'var x: Variant = ...'
# statt ':=' bei JSON-Ergebnissen.

const SAVE_DIR    := "user://savegame/"
const META_FILE   := SAVE_DIR + "world_meta.json"
const SECTORS_DIR := SAVE_DIR + "sectors/"

var world_seed:       int        = 0
var player_position:  Vector3    = Vector3.ZERO
var player_rotation:  Quaternion = Quaternion.IDENTITY
var player_inventory: Dictionary = {"minerals": 0.0, "deuterium": 0.0}
var needs_seed_setup: bool = false

func _ready() -> void:
	_ensure_save_dirs()
	_load_or_create_world_meta()
	print("GameDatabase: Speicherort = %s" % [ProjectSettings.globalize_path(SAVE_DIR)])

func _ensure_save_dirs() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("savegame/sectors")

# --- World-Seed ---

func _load_or_create_world_meta() -> void:
	if not FileAccess.file_exists(META_FILE):
		needs_seed_setup = true
		return
	var f := FileAccess.open(META_FILE, FileAccess.READ)
	if f == null:
		push_error("GameDatabase: world_meta.json kann nicht gelesen werden.")
		needs_seed_setup = true
		return
	var text := f.get_as_text()
	f.close()
	# JSON.parse_string gibt Variant zurueck -> explizit als Variant deklarieren
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		needs_seed_setup = true
		return
	var data: Dictionary = parsed
	if not data.has("world_seed"):
		needs_seed_setup = true
		return

	world_seed = _parse_seed_value(data["world_seed"])

	var p: Dictionary = data.get("player_position", {"x": 0.0, "y": 0.0, "z": 0.0})
	player_position = Vector3(p.get("x", 0.0), p.get("y", 0.0), p.get("z", 0.0))

	var r: Dictionary = data.get("player_rotation", {"x": 0.0, "y": 0.0, "z": 0.0, "w": 1.0})
	player_rotation = Quaternion(r.get("x", 0.0), r.get("y", 0.0), r.get("z", 0.0), r.get("w", 1.0))

	var inv: Dictionary = data.get("player_inventory", {"minerals": 0.0, "deuterium": 0.0})
	player_inventory = {
		"minerals":  float(inv.get("minerals",  0.0)),
		"deuterium": float(inv.get("deuterium", 0.0)),
	}
	needs_seed_setup = false

func _parse_seed_value(raw: Variant) -> int:
	if raw is String:
		return (raw as String).to_int()
	return int(raw)

func _generate_random_seed() -> int:
	randomize()
	var high: int = randi()
	var low:  int = randi()
	return (high << 32) | low

func finish_new_world_setup(custom_seed_text: String = "") -> void:
	if custom_seed_text.strip_edges() != "":
		set_world_seed_from_text(custom_seed_text.strip_edges())
	else:
		world_seed = _generate_random_seed()
		save_world_meta()
	needs_seed_setup = false

func set_world_seed_from_text(text: String) -> void:
	var sha := text.sha256_buffer()
	var seed_int: int = 0
	for i in range(8):
		seed_int = (seed_int << 8) | sha[i]
	world_seed = seed_int
	save_world_meta()

func save_world_meta() -> void:
	var data := {
		"world_seed": str(world_seed),
		"player_position": {"x": player_position.x, "y": player_position.y, "z": player_position.z},
		"player_rotation": {"x": player_rotation.x, "y": player_rotation.y, "z": player_rotation.z, "w": player_rotation.w},
		"player_inventory": player_inventory,
	}
	var f := FileAccess.open(META_FILE, FileAccess.WRITE)
	if f == null:
		push_error("GameDatabase: world_meta.json kann nicht geschrieben werden.")
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()

func save_player_state(pos: Vector3, rot: Quaternion) -> void:
	player_position = pos
	player_rotation = rot
	save_world_meta()

# --- Inventar ---

func get_resource(type: String) -> int:
	return int(player_inventory.get(type, 0.0))

func add_resource(type: String, amount: float) -> void:
	var current: float = float(player_inventory.get(type, 0.0))
	player_inventory[type] = current + amount

func spend_resource(type: String, amount: int) -> bool:
	var current: float = float(player_inventory.get(type, 0.0))
	if int(current) < amount:
		return false
	player_inventory[type] = current - float(amount)
	return true

# --- Sektor-Daten ---

func _sector_file(sector_id: String) -> String:
	return SECTORS_DIR + sector_id + ".json"

func load_sector_data(sector_id: String) -> Dictionary:
	var path := _sector_file(sector_id)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

func save_sector_data(sector_id: String, data: Dictionary) -> void:
	var f := FileAccess.open(_sector_file(sector_id), FileAccess.WRITE)
	if f == null:
		push_error("GameDatabase: Sektordatei kann nicht geschrieben werden: %s" % sector_id)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()

func save_planet_state(sector_id: String, planet_name: String, minerals: float, deuterium: float) -> void:
	var data := load_sector_data(sector_id)
	var min_ov: Dictionary = data.get("planet_resources", {})
	var deu_ov: Dictionary = data.get("planet_deuterium", {})
	min_ov[planet_name] = minerals
	deu_ov[planet_name] = deuterium
	data["planet_resources"] = min_ov
	data["planet_deuterium"] = deu_ov
	save_sector_data(sector_id, data)

func add_station(sector_id: String, station: Dictionary) -> void:
	var data := load_sector_data(sector_id)
	var stations: Array = data.get("stations", [])
	stations.append(station)
	data["stations"] = stations
	save_sector_data(sector_id, data)

func add_ship(sector_id: String, ship: Dictionary) -> void:
	var data := load_sector_data(sector_id)
	var ships: Array = data.get("ships", [])
	ships.append(ship)
	data["ships"] = ships
	save_sector_data(sector_id, data)
