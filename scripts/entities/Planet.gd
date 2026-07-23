class_name Planet
extends Node3D

var planet_data: Dictionary = {}
var star_node:   Node3D     = null

const SELF_ROTATION_SPEED_DEG := 10.0
const TEX_W := 160; const TEX_H := 80
static var _tex_cache: Dictionary = {}

# Orbit-State – rein delta-basiert, kein UTC
var _orbit_angle_deg:      float = 0.0
var _orbit_speed_deg_per_s: float = 0.0

func setup(data: Dictionary, star: Node3D) -> void:
	planet_data = data
	star_node   = star
	add_to_group("planets")

	# Startwinkel aus dem generierten Datum
	_orbit_angle_deg       = float(data.get("orbit_angle",     0.0))
	# Kepler-Geschwindigkeit aus SectorGenerator – Fallback 0.4 °/s (≈ 15 Min Umlauf)
	_orbit_speed_deg_per_s = float(data.get("orbit_speed_deg", 0.4))

	var cls: String      = data["class"]
	var cd: Dictionary   = PlanetClassDB.classes[cls]
	var r: float         = float(data["radius"])

	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new(); sp.radius = r; sp.height = r * 2.0; mi.mesh = sp
	var mat := StandardMaterial3D.new()
	mat.albedo_color   = Color.WHITE
	mat.albedo_texture = _get_tex(cls, cd, String(data["name"]))
	mi.material_override = mat; add_child(mi)

	name = String(data["name"]).replace(" ", "_")
	_apply_orbit_position()   # Startposition sofort setzen

func _process(delta: float) -> void:
	# 1. Eigenrotation (Tagesrotation)
	rotate_y(deg_to_rad(SELF_ROTATION_SPEED_DEG * delta))
	# 2. Orbitalbewegung – nur delta, niemals UTC-Zeit
	_orbit_angle_deg = fmod(_orbit_angle_deg + _orbit_speed_deg_per_s * delta, 360.0)
	_apply_orbit_position()

func _apply_orbit_position() -> void:
	if star_node == null or not is_instance_valid(star_node): return
	var rad: float  = deg_to_rad(_orbit_angle_deg)
	var orb: float  = float(planet_data["orbit_radius"])
	global_position = star_node.global_position + Vector3(cos(rad) * orb, 0.0, sin(rad) * orb)

# ── Textur-Generierung ────────────────────────────────────────────────────────

func _get_tex(_cls: String, cd: Dictionary, pname: String) -> ImageTexture:
	var key: int = (str(GameDatabase.world_seed) + "|" + pname).hash()
	if _tex_cache.has(key): return _tex_cache[key]
	var noise := FastNoiseLite.new(); noise.seed = int(key & 0x7fffffff)
	noise.frequency = 1.6; noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0; noise.fractal_gain = 0.5
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGB8)
	if cd["type"] == "gas": _fill_gas(img, noise, cd["color"])
	else:                   _fill_rocky(img, noise, cd["color"])
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex; return tex

func _sp(u: float, v: float) -> Vector3:
	var lon := u * TAU; var lat := (v - 0.5) * PI
	return Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))

func _fill_rocky(img: Image, noise: FastNoiseLite, base: Color) -> void:
	var dark  := base.darkened(0.35)
	var light := base.lightened(0.25)
	var ice   := Color(0.9, 0.92, 0.95)
	for y in range(TEX_H):
		var v: float  = float(y) / float(TEX_H - 1)
		var ln: float = abs(v - 0.5) * 2.0
		for x in range(TEX_W):
			var u: float    = float(x) / float(TEX_W - 1)
			var p: Vector3  = _sp(u, v)
			var n: float    = (noise.get_noise_3d(p.x, p.y, p.z) + 1.0) * 0.5
			var col: Color  = dark.lerp(base, n * 2.0) if n < 0.5 \
				else base.lerp(light, (n - 0.5) * 2.0)
			if ln > 0.82:
				col = col.lerp(ice, clamp((ln - 0.82) / 0.18, 0.0, 1.0))
			img.set_pixel(x, y, col)

func _fill_gas(img: Image, noise: FastNoiseLite, base: Color) -> void:
	var a := base.darkened(0.25); var b := base.lightened(0.2)
	for y in range(TEX_H):
		var v: float   = float(y) / float(TEX_H - 1)
		var lat: float = (v - 0.5) * PI
		var band: float = sin(lat * 9.0) * 0.5 + 0.5
		for x in range(TEX_W):
			var u: float   = float(x) / float(TEX_W - 1)
			var p: Vector3 = _sp(u, v)
			var t: float   = clamp(
				band + noise.get_noise_3d(p.x * 1.6, p.y * 1.6, p.z * 1.6) * 0.35,
				0.0, 1.0)
			img.set_pixel(x, y, a.lerp(b, t))