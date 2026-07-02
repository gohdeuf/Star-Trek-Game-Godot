extends Node
# Autoload: Locale
#
# Lokalisierungssystem (siehe README "Lokalisierung/Uebersetzung", bewusst
# als letztes Feature umgesetzt, nachdem alle Gameplay-Systeme stehen).
# Laedt Text-Keys aus JSON-Dateien unter res://data/locale/<sprache>.json.
# Neue Sprachen lassen sich rein durch Hinzufuegen einer weiteren JSON-Datei
# ergaenzen -> KEINE Code-Aenderung noetig.
#
# Nutzung im Code:
#   Locale.t("help.title")
#   Locale.t("map.info", {"x": "10", "y": "0", "z": "5", "zoom": "1.0", "count": 3})
#
# Platzhalter in den JSON-Texten werden im Format {key} geschrieben und per
# String.format() ersetzt (siehe t()).

const LOCALE_DIR := "res://data/locale/"
const DEFAULT_LANGUAGE := "de"
const FALLBACK_LANGUAGE := "de"  # falls ein Key in der gewaehlten Sprache fehlt

signal language_changed(language_code: String)

var current_language: String = DEFAULT_LANGUAGE
var available_languages: Array = []

var _strings: Dictionary = {}          # aktuell geladene Sprache
var _fallback_strings: Dictionary = {} # Fallback-Sprache (siehe oben)

func _ready() -> void:
	_scan_available_languages()
	_fallback_strings = _load_language_file(FALLBACK_LANGUAGE)

	# Beim allerersten Start automatisch die OS-Sprache versuchen, falls dafuer
	# eine JSON-Datei existiert; sonst Standard-Sprache (Deutsch).
	var detected := OS.get_locale_language()
	if available_languages.has(detected):
		set_language(detected)
	else:
		set_language(DEFAULT_LANGUAGE)

func _scan_available_languages() -> void:
	available_languages.clear()
	var dir := DirAccess.open(LOCALE_DIR)
	if dir == null:
		push_error("Locale: Ordner %s nicht gefunden." % [LOCALE_DIR])
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			available_languages.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	available_languages.sort()

func set_language(language_code: String) -> void:
	if not available_languages.has(language_code):
		push_error("Locale: Sprache '%s' nicht gefunden (verfuegbar: %s)." % [language_code, available_languages])
		return
	current_language = language_code
	_strings = _load_language_file(language_code)
	language_changed.emit(language_code)

## Schaltet zyklisch zur naechsten verfuegbaren Sprache um (siehe F9-Bindung
## in InputSetup.gd) -- praktisch zum Live-Testen neuer Uebersetzungen.
func cycle_language() -> void:
	if available_languages.is_empty():
		return
	var idx := available_languages.find(current_language)
	idx = (idx + 1) % available_languages.size()
	set_language(available_languages[idx])

func _load_language_file(language_code: String) -> Dictionary:
	var path := LOCALE_DIR + language_code + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Locale: %s konnte nicht gelesen werden." % [path])
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else {}

## Liefert den uebersetzten Text fuer 'key'. Fallback-Kette: aktuelle Sprache
## -> Fallback-Sprache (Deutsch) -> der Key selbst (damit fehlende
## Uebersetzungen im Spiel sofort auffallen statt leer/kaputt zu wirken).
## 'args' (optional) wird per String.format() eingesetzt, siehe Kopfkommentar.
func t(key: String, args = null) -> String:
	var raw: String = _strings.get(key, _fallback_strings.get(key, key))
	if args != null:
		return raw.format(args)
	return raw
