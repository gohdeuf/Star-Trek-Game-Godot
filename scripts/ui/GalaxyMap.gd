class_name GalaxyMap
extends Control
# Galaxiekarte / Minimap (siehe Referenz Abschnitt 11).
# Tab oeffnet/schliesst, Zoom per Mausrad, Schwenken per Linksklick-Drag,
# Hoehenanzeige (Dreieck hoch/runter/Ebene), Spieler-Marker mit Rotation,
# Info-Text (Position/Zoom/Anzahl Systeme).

@export var refresh_interval: float = 2.0
@export var pixels_per_unit: float = 0.05

var player: Node3D
var _systems: Array = []
var _zoom: float = 1.0
var _pan_offset: Vector2 = Vector2.ZERO
var _dragging := false
var _refresh_timer: float = 0.0

func _ready() -> void:
	visible = false
	_refresh_systems()

func set_player(node: Node3D) -> void:
	player = node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		visible = not visible
		get_viewport().set_input_as_handled()
		return

	if not visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clamp(_zoom * 1.1, 0.1, 20.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clamp(_zoom / 1.1, 0.1, 20.0)
		queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		_pan_offset += event.relative
		queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= refresh_interval:
		_refresh_timer = 0.0
		_refresh_systems()
		queue_redraw()

func _refresh_systems() -> void:
	_systems = SectorGenerator.get_cached_systems()

func _world_to_map(pos: Vector3) -> Vector2:
	var center := size / 2.0 + _pan_offset
	return center + Vector2(pos.x, pos.z) * pixels_per_unit * _zoom

func _draw() -> void:
	if player == null:
		return

	var player_map_pos := _world_to_map(player.global_position)

	for sys in _systems:
		var p: Vector3 = sys["position"]
		var map_pos := _world_to_map(p)
		draw_circle(map_pos, 4.0, Color(1.0, 0.9, 0.4))
		draw_string(ThemeDB.fallback_font, map_pos + Vector2(6, -6), sys["name"])

		var height_diff: float = p.y - player.global_position.y
		var indicator := "~"
		var indicator_color := Color(0.7, 0.7, 0.7)
		if height_diff > 50.0:
			indicator = "^"
			indicator_color = Color(1.0, 0.6, 0.1)
		elif height_diff < -50.0:
			indicator = "v"
			indicator_color = Color(0.3, 0.6, 1.0)
		draw_string(ThemeDB.fallback_font, map_pos + Vector2(6, 8), indicator, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, indicator_color)

		if _zoom > 4.0:
			for planet in sys.get("planets", []):
				var pp: Vector3 = p + Vector3(planet["orbit_radius"], 0, 0)
				var planet_map_pos := _world_to_map(pp)
				draw_circle(planet_map_pos, 2.0, Color(0.6, 0.6, 0.9))

	var forward_2d := Vector2(-sin(player.rotation.y), -cos(player.rotation.y))
	draw_line(player_map_pos, player_map_pos + forward_2d * 12.0, Color(0.2, 1.0, 0.3), 2.0)
	draw_circle(player_map_pos, 5.0, Color(0.2, 1.0, 0.3))

	var info := Locale.t("map.info", {
		"x": "%.0f" % player.global_position.x,
		"y": "%.0f" % player.global_position.y,
		"z": "%.0f" % player.global_position.z,
		"zoom": "%.1f" % _zoom,
		"count": _systems.size(),
	})
	draw_string(ThemeDB.fallback_font, Vector2(10, size.y - 10), info)
