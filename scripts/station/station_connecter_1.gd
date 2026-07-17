@tool
extends CSGCombiner3D
enum ANORDNUNG { KREIS, GITTER, REIHE_X, REIHE_Y, REIHE_Z, SPIRALE }
@export var anordnung_modus: ANORDNUNG = ANORDNUNG.KREIS:
	set(wert): anordnung_modus = wert; generiere_elemente()
@export var anzahl_elemente: int = 4:
	set(wert): anzahl_elemente = wert; generiere_elemente()
@export var radius: float = 1.9:
	set(wert): radius = wert; generiere_elemente()
@export var gitter_spalten: int = 4:
	set(wert): gitter_spalten = max(1, wert); generiere_elemente()
@export var gitter_zeilen: int = 2:
	set(wert): gitter_zeilen = max(1, wert); generiere_elemente()
@export var gitter_abstand: float = 0.5:
	set(wert): gitter_abstand = wert; generiere_elemente()
@export var reihen_abstand: float = 0.4:
	set(wert): reihen_abstand = wert; generiere_elemente()
@export var spiralen_radius_start: float = 0.5:
	set(wert): spiralen_radius_start = wert; generiere_elemente()
@export var spiralen_radius_end: float = 2.0:
	set(wert): spiralen_radius_end = wert; generiere_elemente()
@export var spiralen_hoehe: float = 5.0:
	set(wert): spiralen_hoehe = wert; generiere_elemente()
@export var szene_fenster: PackedScene
@export var szene_tuer: PackedScene
@export var szene_modul: PackedScene
@export var szene_custom: PackedScene
enum SZENEN_TYP { FENSTER, TUER, MODUL, CUSTOM }
@export var szenen_typ: SZENEN_TYP = SZENEN_TYP.FENSTER:
	set(wert): szenen_typ = wert; if is_node_ready() or Engine.is_editor_hint(): generiere_elemente()
@export var auto_rotation: bool = true
@export var rotation_achse: Vector3 = Vector3(0, 0, 1)
@export var wiederholungen: int = 1:
	set(wert): wiederholungen = max(1, wert); if is_node_ready() or Engine.is_editor_hint(): generiere_elemente()
@export var wiederholung_achse: Vector3 = Vector3(0, 0, 1):
	set(wert): wiederholung_achse = wert if wert.length() > 0 else Vector3(0,0,1); generiere_elemente()
@export var wiederholung_abstand: float = 1.0:
	set(wert): wiederholung_abstand = wert; generiere_elemente()
func _ready(): generiere_elemente()
func generiere_elemente():
	var szene = _waehle_szene()
	if not szene: return
	for child in get_children():
		if _ist_generiertes_element(child, szene):
			if Engine.is_editor_hint(): child.free()
			else: child.queue_free()
	for schicht in range(wiederholungen):
		var offset = (schicht - (wiederholungen - 1) / 2.0) * wiederholung_abstand
		var schicht_offset = wiederholung_achse * offset
		match anordnung_modus:
			ANORDNUNG.KREIS:   _generiere_kreis(szene, schicht_offset)
			ANORDNUNG.GITTER:  _generiere_gitter(szene, schicht_offset)
			ANORDNUNG.REIHE_X: _generiere_reihe(szene, Vector3(1,0,0), schicht_offset)
			ANORDNUNG.REIHE_Y: _generiere_reihe(szene, Vector3(0,1,0), schicht_offset)
			ANORDNUNG.REIHE_Z: _generiere_reihe(szene, Vector3(0,0,1), schicht_offset)
			ANORDNUNG.SPIRALE: _generiere_spirale(szene, schicht_offset)
func _waehle_szene() -> PackedScene:
	match szenen_typ:
		SZENEN_TYP.FENSTER: return szene_fenster
		SZENEN_TYP.TUER:    return szene_tuer
		SZENEN_TYP.MODUL:   return szene_modul
		SZENEN_TYP.CUSTOM:  return szene_custom
	return null
func _erstelle_element(szene: PackedScene, position: Vector3, rotation_grad: float = 0.0) -> Node3D:
	var element = szene.instantiate(); element.add_to_group("generierte_elemente"); add_child(element)
	if Engine.is_editor_hint(): element.owner = get_tree().edited_scene_root
	element.position = position
	if auto_rotation: element.rotation = rotation_achse * rotation_grad
	return element
func _ist_generiertes_element(node: Node, szene: PackedScene) -> bool:
	if node.is_in_group("generierte_elemente"): return true
	if node is CSGShape3D:
		var scene_path = node.scene_file_path
		if scene_path != "" and szene and scene_path == szene.resource_path: return true
	return false
func _generiere_kreis(szene: PackedScene, schicht_offset: Vector3 = Vector3.ZERO):
	for i in range(anzahl_elemente):
		var winkel = i * (2.0 * PI / anzahl_elemente)
		var pos = Vector3(cos(winkel)*radius, sin(winkel)*radius, 0) + schicht_offset
		_erstelle_element(szene, pos, winkel)
func _generiere_gitter(szene: PackedScene, schicht_offset: Vector3 = Vector3.ZERO):
	var index = 0
	for row in range(gitter_zeilen):
		for col in range(gitter_spalten):
			if index >= anzahl_elemente: return
			var pos = Vector3((col-gitter_spalten/2.0)*gitter_abstand,(row-gitter_zeilen/2.0)*gitter_abstand,0)+schicht_offset
			_erstelle_element(szene, pos); index += 1
func _generiere_reihe(szene: PackedScene, richtung: Vector3, schicht_offset: Vector3 = Vector3.ZERO):
	for i in range(anzahl_elemente):
		var offset = (i - anzahl_elemente / 2.0) * reihen_abstand
		_erstelle_element(szene, richtung * offset + schicht_offset)
func _generiere_spirale(szene: PackedScene, schicht_offset: Vector3 = Vector3.ZERO):
	for i in range(anzahl_elemente):
		var t = float(i) / anzahl_elemente
		var aktueller_radius = lerp(spiralen_radius_start, spiralen_radius_end, t)
		var winkel = t * 4.0 * PI; var hoehe = (t - 0.5) * spiralen_hoehe
		var pos = Vector3(cos(winkel)*aktueller_radius, sin(winkel)*aktueller_radius, hoehe) + schicht_offset
		_erstelle_element(szene, pos, winkel)
