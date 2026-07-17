class_name StationManagement
extends Node
# Stations-Verwaltungspanel (H-Taste oder automatisch beim Andocken).
# Zeigt: Leistung, AM-Rate, Lagerbestand, Modul-Liste.
# D = Einlagern (Schiff -> Station), W = Auslagern (Station -> Schiff).

const SCAN_RADIUS := 250.0
const REFRESH_INT := 0.6

var ship: Node3D = null
var _hud: Node   = null
var is_open: bool  = false
var _ui:    Control = null
var _info_label: Label = null
var _timer: float = 0.0
var _nearest_hub: Node3D = null

func setup(p_ship: Node3D, p_hud: Node) -> void:
	ship = p_ship; _hud = p_hud
	_build_ui()

func _build_ui() -> void:
	_ui = Control.new()
	_ui.anchor_left = 1.0; _ui.anchor_right = 1.0
	_ui.anchor_top = 0.0;  _ui.anchor_bottom = 1.0
	_ui.offset_left = -310; _ui.offset_right = -10
	_ui.offset_top = 10;    _ui.offset_bottom = -10
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.visible = false

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.80)
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0; _ui.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0; vbox.anchor_bottom = 1.0
	vbox.offset_left = 12; vbox.offset_top = 12
	vbox.offset_right = -12; vbox.offset_bottom = -12
	_ui.add_child(vbox)

	var title := Label.new(); title.text = "─── STATION MGMT ───"
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	title.add_theme_font_size_override("font_size", 15); vbox.add_child(title)

	_info_label = Label.new(); _info_label.text = "Suche Station..."
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_label.add_theme_font_size_override("font_size", 12); vbox.add_child(_info_label)

	var sep := HSeparator.new(); vbox.add_child(sep)
	var hint := Label.new()
	hint.text = "[D] Einlagern\n[W] Auslagern\n[H] Schliessen"
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 12); vbox.add_child(hint)

	get_tree().root.call_deferred("add_child", _ui)

func open_panel() -> void:
	if is_open: return
	is_open = true; _ui.visible = true; _timer = REFRESH_INT
	_refresh()

func close_panel() -> void:
	if not is_open: return
	is_open = false; _ui.visible = false

func _process(delta: float) -> void:
	if not is_open: return
	_timer += delta
	if _timer >= REFRESH_INT: _timer = 0.0; _refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		return

	if Input.is_action_just_pressed("station_management"):
		if is_open:
			close_panel()
		else:
			open_panel()
		return

	if not is_open:
		return

	if Input.is_action_just_pressed("deposit_resources"):
		_deposit()
	if Input.is_action_just_pressed("withdraw_resources"):
		_withdraw()

# ---------- Analyse ----------
func _refresh() -> void:
	if ship == null: _info_label.text = "Kein Schiff."; return
	_nearest_hub = _find_nearest_hub()
	if _nearest_hub == null:
		_info_label.text = "Keine Station\nin Reichweite (%d Einh.)" % int(SCAN_RADIUS)
		return

	var sid: String = GameDatabase.get_station_id(_nearest_hub.global_position)
	var parts: Array = _get_nearby_parts(_nearest_hub.global_position)

	# Leistungs-Bilanz
	var power_out: float = 0.0
	var power_dem: float = 0.0
	var fc_count:  int   = 0
	var amf_count: int   = 0
	var st_count:  int   = 0
	for p in parts:
		if p.is_in_group("fusion_cores"):
			power_out += (p as FusionCore).power_output; fc_count += 1
		if p.is_in_group("am_factories"):
			if p is AntimatterFactorySmall: power_dem += AntimatterFactorySmall.REQUIRED_POWER
			elif p is AntimatterFactoryBig: power_dem += AntimatterFactoryBig.REQUIRED_POWER
			amf_count += 1
		if p.is_in_group("storage_containers"): st_count += 1

	# AM-Produktion schaetzen (1 Sek Vorschau)
	var am_rate: float = 0.0
	for p in parts:
		if p.is_in_group("am_factories"):
			var base: float = 0.0
			var req:  float = 1.0
			if p is AntimatterFactorySmall: base = AntimatterFactorySmall.AM_BASE_RATE; req = AntimatterFactorySmall.FULL_POWER
			elif p is AntimatterFactoryBig: base = AntimatterFactoryBig.AM_BASE_RATE;   req = AntimatterFactoryBig.FULL_POWER
			var eff: float = clamp(power_out / req, 0.0, 1.0) if req > 0 else 0.0
			var star: float = AntimatterFactorySmall._get_star_proximity_bonus(p.global_position)
			am_rate += base * eff * star

	# Lagerkapazitaet
	var cap_min: int = st_count * StorageContainer.CAPACITY_PER_UNIT["minerals"]
	var cap_deu: int = st_count * StorageContainer.CAPACITY_PER_UNIT["deuterium"]
	var cap_am:  int = st_count * StorageContainer.CAPACITY_PER_UNIT["antimatter"]
	var stored: Dictionary = GameDatabase.get_station_storage(sid)
	var st_min: int = int(stored.get("minerals",  0.0))
	var st_deu: int = int(stored.get("deuterium", 0.0))
	var st_am:  int = int(stored.get("antimatter",0.0))

	var dist: int = int(ship.global_position.distance_to(_nearest_hub.global_position))
	_info_label.text = (
		"Station (%d Einh.)\n" % dist +
		"─────────────────\n" +
		"Leistung: %.0f / %.0f W\n" % [power_out, power_dem] +
		"AM-Prod:  %.2f AM/Sek\n" % am_rate +
		"─────────────────\n" +
		"Module:  %dx Hub  %dx FC\n" % [_count_group(parts,"main_station_parts"), fc_count] +
		"         %dx AMF  %dx Lager\n" % [amf_count, st_count] +
		"─────────────────\n" +
		"Lager (Min):  %d / %d\n" % [st_min, cap_min] +
		"Lager (Deu):  %d / %d\n" % [st_deu, cap_deu] +
		"Lager (AM):   %d / %d" % [st_am, cap_am]
	)

# ---------- Transfer ----------
func _deposit() -> void:
	if _nearest_hub == null: return
	var sid: String = GameDatabase.get_station_id(_nearest_hub.global_position)
	var parts: Array = _get_nearby_parts(_nearest_hub.global_position)
	var st_count: int = 0
	for p in parts:
		if p.is_in_group("storage_containers"): st_count += 1
	if st_count == 0:
		if _hud: _hud.show_message(Locale.t("station.no_storage")); return
	var cap_min := st_count * StorageContainer.CAPACITY_PER_UNIT["minerals"]
	var cap_deu := st_count * StorageContainer.CAPACITY_PER_UNIT["deuterium"]
	var cap_am  := st_count * StorageContainer.CAPACITY_PER_UNIT["antimatter"]
	GameDatabase.deposit_to_station(sid, cap_min, cap_deu, cap_am)
	if _hud: _hud.show_message(Locale.t("station.deposited"))
	_refresh()

func _withdraw() -> void:
	if _nearest_hub == null: return
	var sid: String = GameDatabase.get_station_id(_nearest_hub.global_position)
	GameDatabase.withdraw_from_station(sid)
	if _hud: _hud.show_message(Locale.t("station.withdrawn"))
	_refresh()

# ---------- Hilfsfunktionen ----------
func _find_nearest_hub() -> Node3D:
	var best: Node3D = null; var best_dist: float = INF
	for node in get_tree().get_nodes_in_group("main_station_parts"):
		var d: float = ship.global_position.distance_to(node.global_position)
		if d < SCAN_RADIUS and d < best_dist: best = node as Node3D; best_dist = d
	# Legacy Station.gd falls kein Hub
	if best == null:
		for node in get_tree().get_nodes_in_group("stations"):
			var d: float = ship.global_position.distance_to(node.global_position)
			if d < SCAN_RADIUS and d < best_dist: best = node as Node3D; best_dist = d
	return best

func _get_nearby_parts(hub_pos: Vector3) -> Array:
	var result: Array = []
	for node in get_tree().get_nodes_in_group("stations"):
		if hub_pos.distance_to(node.global_position) < SCAN_RADIUS:
			result.append(node)
	return result

func _count_group(parts: Array, group: String) -> int:
	var c: int = 0
	for p in parts:
		if p.is_in_group(group): c += 1
	return c
