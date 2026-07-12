class_name Planet
extends Node3D
# Planet: Star-Trek-Klassifizierung D/H/K/L/M/N/Y (fest) bzw. J/T/6/7/9
# (Gasriesen), siehe Referenz Abschnitt 7. Position/Klasse/Radius/Ressourcen
# kommen vollstaendig aus dem (world-seed-deterministischen) SectorGenerator.
#
# Texturen werden prozedural aus FastNoiseLite generiert (siehe Referenz
# Abschnitt 8):
#   - "rocky": 3D-Noise ueber einen Farbverlauf gemappt (auf der Einheitskugel
#     gesampelt -> automatisch nahtlos/kachelbar) + optionale Polkappen
#     (Breitengrad-basiert).
#   - "gas": Sinus-Baender (Breitengrad) kombiniert mit Noise-Turbulenz.
# Der Noise-Seed kombiniert World-Seed + Planetenname, damit derselbe
# Planetenname in unterschiedlichen Welten unterschiedlich aussehen kann.

var planet_data: Dictionary = {}
var star_node: Node3D
const ROTATION_SPEED_DEG := 10.0  # Y-Achsen-Eigenrotation, 10 Grad/s

const TEX_WIDTH  := 160
const TEX_HEIGHT := 80

# Cache ueber alle Planet-Instanzen hinweg, da Sektoren beim Chunk-Loading
# haeufig entladen/neu geladen werden und sonst dieselbe Textur immer wieder
# neu berechnet wuerde.
static var _texture_cache: Dictionary = {}

func setup(data: Dictionary, star: Node3D) -> void:
	planet_data = data
	star_node = star

	# In die Gruppe "planets" eintragen, damit PlayerActions._find_nearby_planet()
	# per get_tree().get_nodes_in_group("planets") alle aktiven Planeten findet.
	add_to_group("planets")

	var cls: String = data["class"]
	var cls_data: Dictionary = PlanetClassDB.classes[cls]
	var planet_radius: float = data["radius"]

	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = planet_radius
	sphere.height  = planet_radius * 2.0
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color   = Color.WHITE
	mat.albedo_texture = _get_planet_texture(cls, cls_data, String(data["name"]))
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	name = String(data["name"]).replace(" ", "_")
	_update_orbit_position()

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(ROTATION_SPEED_DEG * delta))

func _update_orbit_position() -> void:
	if star_node == null:
		return
	var rad := deg_to_rad(float(planet_data["orbit_angle"]))
	var orbit_radius: float = planet_data["orbit_radius"]
	var offset := Vector3(cos(rad) * orbit_radius, 0.0, sin(rad) * orbit_radius)
	global_position = star_node.global_position + offset

# --- Prozedurale Textur (siehe Referenz Abschnitt 8) ---

func _get_planet_texture(_cls: String, cls_data: Dictionary, planet_name: String) -> ImageTexture:
	var cache_key: int = _texture_seed(planet_name)
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var noise := FastNoiseLite.new()
	noise.seed = int(cache_key & 0x7fffffff)
	noise.frequency = 1.6
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	var img := Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGB8)
	var base_color: Color = cls_data["color"]
	var is_gas: bool = cls_data["type"] == "gas"

	if is_gas:
		_paint_gas_giant(img, noise, base_color)
	else:
		_paint_rocky_planet(img, noise, base_color)

	var tex := ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

func _texture_seed(planet_name: String) -> int:
	var combined := str(GameDatabase.world_seed) + "|" + planet_name
	return combined.hash()

## Wandelt UV-Koordinaten in einen Punkt auf der Einheitskugel um.
func _sphere_point(u: float, v: float) -> Vector3:
	var lon := u * TAU
	var lat := (v - 0.5) * PI
	return Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))

func _paint_rocky_planet(img: Image, noise: FastNoiseLite, base_color: Color) -> void:
	var dark  := base_color.darkened(0.35)
	var light := base_color.lightened(0.25)
	var ice   := Color(0.9, 0.92, 0.95)

	for y in range(TEX_HEIGHT):
		var v := float(y) / float(TEX_HEIGHT - 1)
		var lat_norm: float = abs(v - 0.5) * 2.0
		for x in range(TEX_WIDTH):
			var u := float(x) / float(TEX_WIDTH - 1)
			var p := _sphere_point(u, v)
			var n := noise.get_noise_3d(p.x, p.y, p.z)
			var t := (n + 1.0) * 0.5
			var col: Color
			if t < 0.5:
				col = dark.lerp(base_color, t * 2.0)
			else:
				col = base_color.lerp(light, (t - 0.5) * 2.0)
			if lat_norm > 0.82:
				var cap_blend: float = clamp((lat_norm - 0.82) / 0.18, 0.0, 1.0)
				col = col.lerp(ice, cap_blend)
			img.set_pixel(x, y, col)

func _paint_gas_giant(img: Image, noise: FastNoiseLite, base_color: Color) -> void:
	var band_color_a := base_color.darkened(0.25)
	var band_color_b := base_color.lightened(0.2)

	for y in range(TEX_HEIGHT):
		var v := float(y) / float(TEX_HEIGHT - 1)
		var lat := (v - 0.5) * PI
		var band := sin(lat * 9.0) * 0.5 + 0.5
		for x in range(TEX_WIDTH):
			var u := float(x) / float(TEX_WIDTH - 1)
			var p := _sphere_point(u, v)
			var turbulence := noise.get_noise_3d(p.x * 1.6, p.y * 1.6, p.z * 1.6)
			var t: float = clamp(band + turbulence * 0.35, 0.0, 1.0)
			var col := band_color_a.lerp(band_color_b, t)
			img.set_pixel(x, y, col)
