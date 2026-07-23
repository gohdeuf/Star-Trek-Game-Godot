extends Node
const LOCALE_DIR:="res://data/locale/"
const DEFAULT_LANGUAGE:="de"
signal language_changed(language_code:String)
var current_language:String=DEFAULT_LANGUAGE
var available_languages:Array=[]
var _strings:Dictionary={}
var _fallback_strings:Dictionary={}
func _ready()->void:
	_scan(); _fallback_strings=_load("de")
	var d:=OS.get_locale_language()
	set_language(d if available_languages.has(d) else DEFAULT_LANGUAGE)
func _scan()->void:
	available_languages.clear()
	var dir:=DirAccess.open(LOCALE_DIR)
	if dir==null: push_error("Locale: Ordner nicht gefunden"); return
	dir.list_dir_begin()
	var f:=dir.get_next()
	while f!="":
		if not dir.current_is_dir() and f.ends_with(".json"): available_languages.append(f.get_basename())
		f=dir.get_next()
	dir.list_dir_end(); available_languages.sort()
func set_language(code:String)->void:
	if not available_languages.has(code): return
	current_language=code; _strings=_load(code); language_changed.emit(code)
func cycle_language()->void:
	if available_languages.is_empty(): return
	var i:=(available_languages.find(current_language)+1)%available_languages.size()
	set_language(available_languages[i])
func _load(code:String)->Dictionary:
	var path:=LOCALE_DIR+code+".json"
	if not FileAccess.file_exists(path): return {}
	var f:=FileAccess.open(path,FileAccess.READ)
	if f==null: return {}
	var d=JSON.parse_string(f.get_as_text()); f.close()
	return d if d is Dictionary else {}
func t(key:String,args=null)->String:
	var raw:String=_strings.get(key,_fallback_strings.get(key,key))
	return raw.format(args) if args!=null else raw
