extends Node
# Autoload: GameDatabase
#
# Persistenzschicht (JSON-basiert statt SQLite, siehe Referenz Abschnitt 2).
# Speichert:
#   - world_meta.json: World-Seed (Minecraft-Stil, siehe Abschnitt 3) + letzte Spielerposition
#   - sectors/<sector_id>.json: vom Spieler veraenderte Daten eines Sektors
#     (Stationen, Schiffe, abgebaute Planeten-Ressourcen)

const SAVE_DIR := "user://savegame/"
const META_FILE := SAVE_DIR + "world_meta.json"
const SECTORS_DIR := SAVE_DIR + "sectors/"

var world_seed: int = 0
var player_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	_ensure_save_dirs()
	_load_or_create_world_meta()

func _ensure_save_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(SECTORS_DIR)

# --- World-Seed (siehe Referenz Abschnitt 3) ---

func _load_or_create_world_meta() -> void:
	if FileAccess.file_exists(META_FILE):
		var f := FileAccess.open(META_FILE, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		if data is Dictionary and data.has("world_seed"):
			world_seed = int(data["world_seed"])
			var p: Dictionary = data.get("player_position", {"x": 0, "y": 0, "z": 0})
			player_position = Vector3(p.get("x", 0.0), p.get("y", 0.0), p.get("z", 0.0))
			return
	# Kein gespeicherter Seed vorhanden -> neue Welt, einmalig zufaelligen
	# World-Seed erzeugen und SOFORT speichern, bevor irgendeine
	# Sektorgenerierung stattfindet.
	world_seed = _generate_random_seed()
	save_world_meta()

func _generate_random_seed() -> int:
	randomize()
	var high := randi()
	var low := randi()
	return (high << 32) | low

## Optional: Spieler gibt beim Erstellen einer neuen Welt einen eigenen
## Seed (Text oder Zahl) ein, der gehasht wird (Minecraft-Stil, Abschnitt 3.4).
func set_world_seed_from_text(text: String) -> void:
	world_seed = text.hash()
	save_world_meta()

func save_world_meta() -> void:
	var data := {
		"world_seed": world_seed,
		"player_position": {
			"x": player_position.x,
			"y": player_position.y,
			"z": player_position.z,
		},
	}
	var f := FileAccess.open(META_FILE, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()

func save_player_position(pos: Vector3) -> void:
	player_position = pos
	save_world_meta()

# --- Sektor-Daten (Stationen, Schiffe, Ressourcen-Overrides) ---

func _sector_file(sector_id: String) -> String:
	return SECTORS_DIR + sector_id + ".json"

func load_sector_data(sector_id: String) -> Dictionary:
	var path := _sector_file(sector_id)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else {}

func save_sector_data(sector_id: String, data: Dictionary) -> void:
	var f := FileAccess.open(_sector_file(sector_id), FileAccess.WRITE)
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
