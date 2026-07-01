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

## True zwischen dem allerersten Start einer neuen Welt (noch keine Save-Datei
## vorhanden) und der Bestaetigung im WorldSeedDialog. Solange dieser Wert
## true ist, ist world_seed noch NICHT final gesetzt -> Main.gd darf in
## diesem Zustand noch keine Sektorgenerierung anstossen!
var needs_seed_setup: bool = false

func _ready() -> void:
	_ensure_save_dirs()
	_load_or_create_world_meta()
	# Hinweis: "user://" ist KEIN Ordner im Godot-Projektverzeichnis, sondern
	# zeigt auf einen OS-spezifischen Nutzerdaten-Ordner. Diese Zeile gibt den
	# tatsaechlichen, absoluten Pfad im Godot-Output-Panel aus, damit man die
	# Speicherdatei im Explorer/Finder wiederfindet. Alternativ im Editor:
	# Menue "Projekt" -> "Nutzerdaten-Ordner oeffnen" (Godot 4.3).
	print("GameDatabase: Speicherort = %s" % [ProjectSettings.globalize_path(SAVE_DIR)])

func _ensure_save_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(SECTORS_DIR)

# --- World-Seed (siehe Referenz Abschnitt 3) ---

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
	# Kein gespeicherter Seed vorhanden -> neue Welt. Die eigentliche
	# Seed-Erzeugung wird zurueckgestellt, bis der Spieler im
	# WorldSeedDialog optional einen eigenen Seed eingegeben hat
	# (siehe finish_new_world_setup(), aufgerufen von Main.gd).
	needs_seed_setup = true

func _parse_seed_value(raw) -> int:
	# BUGFIX: Aeltere Speicherstaende hatten den Seed als reine JSON-Zahl
	# abgelegt. JSON kennt nur 64-Bit-Floats (max. ~2^53 verlustfrei
	# darstellbar); ein 64-Bit-Int-Seed (bis ~1.8e19) wird beim Parsen dadurch
	# gerundet. Das war die Ursache dafuer, dass nach einem Neustart ein
	# ANDERER Seed geladen wurde als urspruenglich gespeichert -> andere
	# Sektorinhalte trotz "derselben" Welt. Neue Speicherstaende legen den
	# Seed daher als String ab (siehe save_world_meta()), der hier verlustfrei
	# zurueckkonvertiert wird. Alte Zahlen-Speicherstaende werden weiterhin
	# gelesen (Abwaertskompatibilitaet), koennen aber noch den alten,
	# gerundeten Seed enthalten.
	if raw is String:
		return raw.to_int()
	return int(raw)

func _generate_random_seed() -> int:
	randomize()
	var high := randi()
	var low := randi()
	return (high << 32) | low

## Wird einmalig aufgerufen, nachdem der Spieler im WorldSeedDialog bestaetigt
## hat (siehe Main.gd). Setzt entweder einen aus Text abgeleiteten Seed oder
## einen zufaelligen 64-Bit-Seed und speichert ihn sofort, bevor irgendeine
## Sektorgenerierung stattfindet (siehe Referenz Abschnitt 3, Punkt 2).
func finish_new_world_setup(custom_seed_text: String = "") -> void:
	if custom_seed_text.strip_edges() != "":
		set_world_seed_from_text(custom_seed_text.strip_edges())
	else:
		world_seed = _generate_random_seed()
		save_world_meta()
	needs_seed_setup = false

## Optional: Spieler gibt beim Erstellen einer neuen Welt einen eigenen
## Seed (Text oder Zahl) ein (Minecraft-Stil, Referenz Abschnitt 3.4). Wird
## per SHA256 auf einen vollen 64-Bit-Wert gehasht (analog zu
## SectorUtils.seed_for_sector), fuer eine bessere Verteilung als ein
## einfacher 32-Bit-String-Hash.
func set_world_seed_from_text(text: String) -> void:
	var sha := text.sha256_buffer()
	var seed_int: int = 0
	for i in range(8):
		seed_int = (seed_int << 8) | sha[i]
	world_seed = seed_int
	save_world_meta()

func save_world_meta() -> void:
	var data := {
		# BUGFIX: als String gespeichert statt als Zahl (siehe _parse_seed_value
		# fuer die Begruendung) -> verlustfreier Roundtrip fuer 64-Bit-Seeds.
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

# --- Sektor-Daten (Stationen, Schiffe, Ressourcen-Overrides) ---

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
