extends Node
# Autoload: GameDatabase
#
# Persistenzschicht (JSON-basiert, siehe Referenz Abschnitt 2).
# Speichert:
#   - world_meta.json: World-Seed + letzte Spielerposition
#   - sectors/<sector_id>.json: vom Spieler veraenderte Sektordaten

const SAVE_DIR    := "user://savegame/"
const META_FILE   := SAVE_DIR + "world_meta.json"
const SECTORS_DIR := SAVE_DIR + "sectors/"

var world_seed:      int     = 0
var player_position: Vector3 = Vector3.ZERO

## True zwischen dem allerersten Start und der Bestaetigung im WorldSeedDialog.
var needs_seed_setup: bool = false

func _ready() -> void:
	_ensure_save_dirs()
	_load_or_create_world_meta()
	print("GameDatabase: Speicherort = %s" % [ProjectSettings.globalize_path(SAVE_DIR)])

func _ensure_save_dirs() -> void:
	# BUGFIX: make_dir_recursive_absolute akzeptiert keine virtuellen Godot-
	# Pfade (user://). Stattdessen DirAccess.open("user://") + make_dir_recursive
	# mit relativem Pfad verwenden, was den vollen Pfad user://savegame/sectors
	# rekursiv anlegt.
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("savegame/sectors")

# --- World-Seed ---

func _load_or_create_world_meta() -> void:
	if FileAccess.file_exists(META_FILE):
		var f := FileAccess.open(META_FILE, FileAccess.READ)
		if f != null:
			var data = JSON.parse_string(f.get_as_text())
			f.close()
			if data is Dictionary and data.has("world_seed"):
				world_seed = _parse_seed_value(data["world_seed"])
				var p: Dictionary = data.get("player_position", {"x": 0, "y": 0, "z": 0})
				player_position = Vector3(p.get("x", 0.0), p.get("y", 0.0), p.get("z", 0.0))
				needs_seed_setup = false
				return
		else:
			push_error("GameDatabase: world_meta.json konnte nicht gelesen werden (%s)." % [error_string(FileAccess.get_open_error())])
	needs_seed_setup = true

func _parse_seed_value(raw) -> int:
	if raw is String:
		return raw.to_int()
	return int(raw)

func _generate_random_seed() -> int:
	randomize()
	var high := randi()
	var low  := randi()
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
		"player_position": {
			"x": player_position.x,
			"y": player_position.y,
			"z": player_position.z,
		},
	}
	var f := FileAccess.open(META_FILE, FileAccess.WRITE)
	if f == null:
		push_error("GameDatabase: world_meta.json konnte nicht geschrieben werden (%s)." % [error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	print("GameDatabase: world_meta.json gespeichert (%s)" % [ProjectSettings.globalize_path(META_FILE)])

func save_player_position(pos: Vector3) -> void:
	player_position = pos
	save_world_meta()

# --- Sektor-Daten ---

func _sector_file(sector_id: String) -> String:
	return SECTORS_DIR + sector_id + ".json"

func load_sector_data(sector_id: String) -> Dictionary:
	var path := _sector_file(sector_id)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameDatabase: Sektordatei konnte nicht gelesen werden: %s" % [sector_id])
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else {}

func save_sector_data(sector_id: String, data: Dictionary) -> void:
	var f := FileAccess.open(_sector_file(sector_id), FileAccess.WRITE)
	if f == null:
		push_error("GameDatabase: Sektordatei konnte nicht geschrieben werden: %s" % [sector_id])
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()

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

func update_planet_resource(sector_id: String, planet_name: String, current_value: float) -> void:
	var data := load_sector_data(sector_id)
	var overrides: Dictionary = data.get("planet_resources", {})
	overrides[planet_name] = current_value
	data["planet_resources"] = overrides
	save_sector_data(sector_id, data)
