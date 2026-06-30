extends Node
# Autoload: SectorGenerator
#
# Deterministische Sektorgenerierung aus (world_seed, sector_id), siehe
# Referenz Abschnitt 3. Gleicher Sektor -> immer gleicher Inhalt innerhalb
# derselben Welt; unterschiedliche Welten (world_seed) -> unterschiedliche Inhalte.

const SYSTEM_SPAWN_CHANCE := 0.35
const SOI_MIN := 300.0
const SOI_MAX := 750.0
const PLANETS_MIN := 0
const PLANETS_MAX := 5

# Cache: sector_id -> generierte Systemdaten (leeres Dictionary = kein System)
var _cache: Dictionary = {}

func ensure_sector_generated(sector_id: String) -> Dictionary:
	if _cache.has(sector_id):
		return _cache[sector_id]

	var result := _generate_sector(sector_id)
	_apply_resource_overrides(sector_id, result)
	_cache[sector_id] = result
	return result

func get_cached_systems() -> Array:
	var result: Array = []
	for sector_id in _cache.keys():
		var sys: Dictionary = _cache[sector_id]
		if not sys.is_empty():
			result.append(sys)
	return result

func _generate_sector(sector_id: String) -> Dictionary:
	var sector_seed := SectorUtils.seed_for_sector(GameDatabase.world_seed, sector_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = sector_seed

	if rng.randf() > SYSTEM_SPAWN_CHANCE:
		return {}

	var coords := SectorUtils.sector_id_to_coords(sector_id)
	var origin := Vector3(coords.x, coords.y, coords.z) * SectorUtils.SECTOR_SIZE
	var star_pos := origin + Vector3(
		rng.randf_range(0.0, SectorUtils.SECTOR_SIZE),
		rng.randf_range(0.0, SectorUtils.SECTOR_SIZE),
		rng.randf_range(0.0, SectorUtils.SECTOR_SIZE)
	)

	var soi := rng.randf_range(SOI_MIN, SOI_MAX)
	var star_name: String = StarNames.random_name(rng)

	var planet_count := rng.randi_range(PLANETS_MIN, PLANETS_MAX)
	var planets: Array = []
	var orbit_radius := 20.0
	for i in range(planet_count):
		var cls: String = PlanetClassDB.weighted_random_class(rng)
		orbit_radius += rng.randf_range(15.0, 40.0)
		var orbit_angle := rng.randf_range(0.0, 360.0)
		var resources: Dictionary = PlanetClassDB.random_resources(rng, cls)
		var radius_range: Array = PlanetClassDB.classes[cls]["radius"]
		var planet_radius := rng.randf_range(radius_range[0], radius_range[1])
		var roman := _to_roman(i + 1)
		planets.append({
			"name": "%s %s" % [star_name, roman],
			"class": cls,
			"orbit_radius": orbit_radius,
			"orbit_angle": orbit_angle,
			"radius": planet_radius,
			"resources": resources,
		})
		orbit_radius += rng.randf_range(5.0, 15.0)

	return {
		"system_id": sector_id + "_sys",
		"sector_id": sector_id,
		"name": star_name,
		"position": star_pos,
		"sphere_of_influence": soi,
		"planets": planets,
	}

func _apply_resource_overrides(sector_id: String, system: Dictionary) -> void:
	if system.is_empty():
		return
	var saved := GameDatabase.load_sector_data(sector_id)
	var overrides: Dictionary = saved.get("planet_resources", {})
	if overrides.is_empty():
		return
	for planet in system["planets"]:
		if overrides.has(planet["name"]):
			planet["resources"]["current"] = overrides[planet["name"]]

func _to_roman(num: int) -> String:
	var vals := [10, 9, 5, 4, 1]
	var syms := ["X", "IX", "V", "IV", "I"]
	var result := ""
	var n := num
	for i in range(vals.size()):
		while n >= vals[i]:
			result += syms[i]
			n -= vals[i]
	return result
