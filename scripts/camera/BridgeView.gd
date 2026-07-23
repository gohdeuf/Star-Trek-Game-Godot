class_name BridgeView
extends Node3D

# Erste-Person-Brücke – Kamera ist Kind des Schiffs.
# Kein look_at() → kein Gimbal-Lock egal bei welcher Fluglage.
# "Viewscreen": einfach die Lücke in der Geometrie nach vorne.
# Alle Maße relativ zu S = Saucer-Radius (0.03 Units).

const S: float = 0.03

var bridge_cam: Camera3D = null
var is_active:  bool     = false

func _ready() -> void:
	_build_interior()
	visible = false

# ── Öffentliche API ───────────────────────────────────────────────────────────
func activate(follow_cam: Camera3D) -> void:
	visible            = true
	is_active          = true
	follow_cam.current = false
	bridge_cam.current = true

func deactivate(follow_cam: Camera3D) -> void:
	visible            = false
	is_active          = false
	bridge_cam.current = false
	follow_cam.current = true

# ── Innenraum-Aufbau ──────────────────────────────────────────────────────────
func _build_interior() -> void:
	# Brückenkamera – Augenposition, leicht über Schiffsmitte, leicht nach vorne
	bridge_cam          = Camera3D.new()
	bridge_cam.position = Vector3(0.0, S * 0.18, -S * 0.05)
	bridge_cam.near     = 0.0005   # sehr kleiner Clip damit Wände nicht durch die Kamera schneiden
	bridge_cam.fov      = 90.0
	add_child(bridge_cam)

	# Materialien
	var mat_hull  := _solid(Color(0.07, 0.09, 0.13), 0.75)
	var mat_panel := _solid(Color(0.11, 0.14, 0.20), 0.70)
	var mat_glow  := _solid(Color(0.05, 0.30, 0.85), 0.0)
	mat_glow.emission_enabled            = true
	mat_glow.emission                    = Color(0.04, 0.26, 0.78)
	mat_glow.emission_energy_multiplier  = 3.5

	var mat_screen := _solid(Color(0.02, 0.08, 0.14), 0.0)
	mat_screen.emission_enabled           = true
	mat_screen.emission                   = Color(0.02, 0.06, 0.12)
	mat_screen.emission_energy_multiplier = 0.4

	# ── Boden ────────────────────────────────────────────────────────────────
	_box(Vector3(S*1.9, S*0.05, S*1.6), Vector3(0, -S*0.20, S*0.05), mat_hull)

	# ── Decke ────────────────────────────────────────────────────────────────
	_box(Vector3(S*1.9, S*0.05, S*1.6), Vector3(0,  S*0.72, S*0.05), mat_hull)

	# ── Seitenwände ──────────────────────────────────────────────────────────
	for side in [-1, 1]:
		_box(Vector3(S*0.05, S*0.92, S*1.6),
			Vector3(float(side)*S*0.95, S*0.26, S*0.05), mat_hull)

	# ── Rückwand ─────────────────────────────────────────────────────────────
	_box(Vector3(S*1.9, S*0.92, S*0.05), Vector3(0, S*0.26, S*0.85), mat_hull)

	# ── Konsole (unteres Vorderpanel) ────────────────────────────────────────
	_box(Vector3(S*1.72, S*0.34, S*0.42), Vector3(0, -S*0.03, -S*0.44), mat_panel)

	# Glow-Streifen auf Konsole
	for sx: float in [-0.55, 0.0, 0.55]:
		_box(Vector3(S*0.42, S*0.03, S*0.38),
			Vector3(sx*S*1.1, S*0.14, -S*0.44), mat_glow)

	# Konsolen-Trennlinien
	for sx: float in [-0.28, 0.28]:
		_box(Vector3(S*0.02, S*0.36, S*0.44),
			Vector3(sx*S*1.9, S*0.00, -S*0.44), mat_hull)

	# ── Viewscreen-Rahmen (Öffnung nach vorne = freier Blick auf Weltraum) ────
	# Oben
	_box(Vector3(S*1.90, S*0.09, S*0.05),
		Vector3(0.0,         S*0.64, -S*0.86), mat_hull)
	# Links
	_box(Vector3(S*0.05, S*0.70, S*0.05),
		Vector3(-S*0.90,  S*0.29, -S*0.86), mat_hull)
	# Rechts
	_box(Vector3(S*0.05, S*0.70, S*0.05),
		Vector3( S*0.90,  S*0.29, -S*0.86), mat_hull)
	# Unter-Leiste (über Konsole)
	_box(Vector3(S*1.90, S*0.05, S*0.05),
		Vector3(0.0,         -S*0.06, -S*0.86), mat_hull)

	# Viewscreen-Randbeleuchtung (cyan-blauer Schein)
	var edge_glow := _solid(Color(0.0, 0.55, 0.95), 0.0)
	edge_glow.emission_enabled           = true
	edge_glow.emission                   = Color(0.0, 0.45, 0.85)
	edge_glow.emission_energy_multiplier = 2.0
	_box(Vector3(S*1.82, S*0.02, S*0.02), Vector3(0.0, S*0.59,  -S*0.87), edge_glow)  # oben
	_box(Vector3(S*1.82, S*0.02, S*0.02), Vector3(0.0, -S*0.03, -S*0.87), edge_glow)  # unten

	# ── Deckenleuchten ────────────────────────────────────────────────────────
	for lx: float in [-0.5, 0.0, 0.5]:
		var l := OmniLight3D.new()
		l.light_color  = Color(0.72, 0.86, 1.0)
		l.omni_range   = S * 2.8
		l.light_energy = 0.55
		l.position     = Vector3(lx * S * 0.8, S * 0.64, S * 0.1)
		add_child(l)

	# ── Seitliche Arm-Konsolen ─────────────────────────────────────────────────
	for side in [-1, 1]:
		_box(Vector3(S*0.18, S*0.06, S*0.5),
			Vector3(float(side)*S*0.77, -S*0.06, S*0.15), mat_panel)
		_box(Vector3(S*0.14, S*0.02, S*0.46),
			Vector3(float(side)*S*0.77, -S*0.02, S*0.15), mat_glow)

# ── Hilfsfunktionen ───────────────────────────────────────────────────────────
func _solid(color: Color, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.metallic = metallic
	return m

func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.material_override = mat; mi.position = pos
	add_child(mi)