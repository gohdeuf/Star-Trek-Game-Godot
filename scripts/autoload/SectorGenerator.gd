extends Node
const SYSTEM_SPAWN_CHANCE := 0.35
const SOI_MIN := 300.0; const SOI_MAX := 750.0
const PLANETS_MIN := 0;  const PLANETS_MAX := 5
const MOON_CHANCE_ROCKY := 0.28; const MOON_CHANCE_GAS := 0.55
const MAX_MOONS_ROCKY := 2;      const MAX_MOONS_GAS   := 4
const SOL_SECTOR_ID := "Sector_Alpha_0_0_0"
const SECTOR_UTILS  := preload("res://scripts/autoload/SectorUtils.gd")

# Kepler III: Referenzorbit bei 80 Einh. Radius → 15 Minuten Echtzeit
const ORBIT_REFERENCE_RADIUS := 80.0
const ORBIT_REFERENCE_PERIOD := 900.0  # Sekunden

var _cache: Dictionary = {}

func ensure_sector_generated(sector_id: String) -> Dictionary:
	if _cache.has(sector_id): return _cache[sector_id]
	var result := _generate_sector(sector_id)
	_apply_resource_overrides(sector_id, result)
	_cache[sector_id] = result; return result

func get_cached_systems() -> Array:
	var result: Array = []
	for sector_id in _cache.keys():
		var sys: Dictionary = _cache[sector_id]
		if not sys.is_empty(): result.append(sys)
	return result

# ── Kepler: ω = 360 / T,  T ∝ r^(3/2) ───────────────────────────────────────
func _orbit_speed_deg(orbit_radius: float) -> float:
	var period: float = ORBIT_REFERENCE_PERIOD * pow(orbit_radius / ORBIT_REFERENCE_RADIUS, 1.5)
	return 360.0 / period

func _generate_sector(sector_id: String) -> Dictionary:
	if sector_id == SOL_SECTOR_ID: return _build_sol_system()
	var sector_seed: int = SECTOR_UTILS.seed_for_sector(GameDatabase.world_seed, sector_id)
	var rng := RandomNumberGenerator.new(); rng.seed = sector_seed
	if rng.randf() > SYSTEM_SPAWN_CHANCE: return {}
	var coords: Vector3i = SECTOR_UTILS.sector_id_to_coords(sector_id)
	var origin := Vector3(coords.x, coords.y, coords.z) * SECTOR_UTILS.SECTOR_SIZE
	var star_pos := origin + Vector3(
		rng.randf_range(0.0, SECTOR_UTILS.SECTOR_SIZE),
		rng.randf_range(0.0, SECTOR_UTILS.SECTOR_SIZE),
		rng.randf_range(0.0, SECTOR_UTILS.SECTOR_SIZE))
	var soi: float      = rng.randf_range(SOI_MIN, SOI_MAX)
	var star_name: String = StarNames.random_name(rng)
	var planet_count    := rng.randi_range(PLANETS_MIN, PLANETS_MAX)
	var planets: Array  = []; var orbit_radius := 0.0; var prev_planet_radius := 0.0
	for i in range(planet_count):
		var cls: String = PlanetClassDB.weighted_random_class(rng)
		var radius_range: Array = PlanetClassDB.classes[cls]["radius"]
		var planet_radius: float = rng.randf_range(float(radius_range[0]), float(radius_range[1]))
		orbit_radius      += prev_planet_radius + planet_radius + rng.randf_range(45.0, 80.0)
		prev_planet_radius = planet_radius
		var orbit_angle: float = rng.randf_range(0.0, 360.0)
		var resources          := PlanetClassDB.random_resources(rng, cls)
		var deuterium          := PlanetClassDB.random_deuterium(rng, cls)
		var planet_name        := "%s %s" % [star_name, _to_roman(i + 1)]
		planets.append({
			"name": planet_name, "class": cls,
			"orbit_radius":    orbit_radius,
			"orbit_angle":     orbit_angle,
			"orbit_speed_deg": _orbit_speed_deg(orbit_radius),   # ← Kepler-basiert
			"radius":          planet_radius,
			"resources":       resources,
			"deuterium":       deuterium,
			"moons":           _generate_moons(rng, cls, planet_radius, planet_name),
		})
	return {
		"system_id": sector_id + "_sys", "sector_id": sector_id, "name": star_name,
		"position": star_pos, "sphere_of_influence": soi, "planets": planets,
	}

func _generate_moons(rng: RandomNumberGenerator, cls: String, planet_radius: float, planet_name: String) -> Array:
	var is_gas: bool    = PlanetClassDB.classes[cls]["type"] == "gas"
	var chance: float   = MOON_CHANCE_GAS  if is_gas else MOON_CHANCE_ROCKY
	var max_moons: int  = MAX_MOONS_GAS    if is_gas else MAX_MOONS_ROCKY
	var moons: Array    = []; var orbit_radius: float = planet_radius + rng.randf_range(4.0, 8.0)
	for _i in range(max_moons):
		if rng.randf() > chance: continue
		orbit_radius += rng.randf_range(3.0, 9.0)
		moons.append({
			"name":             "%s %s" % [planet_name, _moon_letter(moons.size())],
			"orbit_radius":     orbit_radius,
			"angular_speed_deg": rng.randf_range(10.0, 40.0),
		})
	return moons

func _moon_letter(index: int) -> String: return ["a","b","c","d"][index % 4]

func _build_sol_system() -> Dictionary:
	var planet_defs := [
		{"name":"Merkur", "class":"D","orbit_radius": 30.0,"moons":[]},
		{"name":"Venus",  "class":"H","orbit_radius": 55.0,"moons":[]},
		{"name":"Erde",   "class":"M","orbit_radius": 80.0,"moons":[{"suffix":"Luna",     "speed":15.0}]},
		{"name":"Mars",   "class":"K","orbit_radius":105.0,"moons":[{"suffix":"Phobos",   "speed":35.0},{"suffix":"Deimos","speed":20.0}]},
		{"name":"Jupiter","class":"J","orbit_radius":190.0,"moons":[{"suffix":"Io",       "speed":30.0},{"suffix":"Europa","speed":24.0},{"suffix":"Ganymed","speed":18.0},{"suffix":"Callisto","speed":12.0}]},
		{"name":"Saturn", "class":"T","orbit_radius":280.0,"moons":[{"suffix":"Titan",    "speed":16.0},{"suffix":"Enceladus","speed":26.0}]},
		{"name":"Uranus", "class":"6","orbit_radius":360.0,"moons":[{"suffix":"Titania",  "speed":14.0}]},
		{"name":"Neptun", "class":"7","orbit_radius":430.0,"moons":[{"suffix":"Triton",   "speed":13.0}]},
		{"name":"Pluto",  "class":"Y","orbit_radius":490.0,"moons":[{"suffix":"Charon",   "speed":10.0}]},
	]
	var angle_step: float = 360.0 / float(planet_defs.size())
	var planets: Array = []
	for i in range(planet_defs.size()):
		var def: Dictionary    = planet_defs[i]; var cls: String = def["class"]
		var rr: Array          = PlanetClassDB.classes[cls]["radius"]
		var planet_radius: float = (float(rr[0]) + float(rr[1])) * 0.5
		var res_r: Array       = PlanetClassDB.classes[cls]["resources"]
		var deu_r: Array       = PlanetClassDB.classes[cls]["deuterium"]
		var moons: Array       = []; var moon_orbit: float = planet_radius + 4.0
		for md in def["moons"]:
			moon_orbit += 4.0
			moons.append({"name":"%s %s"%[def["name"],md["suffix"]],"orbit_radius":moon_orbit,"angular_speed_deg":md["speed"]})
		planets.append({
			"name":  def["name"], "class": cls,
			"orbit_radius":    def["orbit_radius"],
			"orbit_angle":     angle_step * float(i),
			"orbit_speed_deg": _orbit_speed_deg(def["orbit_radius"]),  # ← Kepler
			"radius":          planet_radius,
			"resources":       {"max":(float(res_r[0])+float(res_r[1]))*0.5, "current":(float(res_r[0])+float(res_r[1]))*0.5},
			"deuterium":       {"max":(float(deu_r[0])+float(deu_r[1]))*0.5, "current":(float(deu_r[0])+float(deu_r[1]))*0.5},
			"moons": moons,
		})
	return {
		"system_id": SOL_SECTOR_ID+"_sys","sector_id": SOL_SECTOR_ID,"name":"Sol",
		"position": Vector3.ZERO,"sphere_of_influence": SOI_MAX,"planets": planets,
	}

func _apply_resource_overrides(sector_id: String, system: Dictionary) -> void:
	if system.is_empty(): return
	var saved    := load_sector_data_safe(sector_id)
	var min_ov: Dictionary = saved.get("planet_resources",{})
	var deu_ov: Dictionary = saved.get("planet_deuterium",{})
	if min_ov.is_empty() and deu_ov.is_empty(): return
	for planet in system["planets"]:
		var pname: String = planet["name"]
		if min_ov.has(pname): planet["resources"]["current"] = float(min_ov[pname])
		if deu_ov.has(pname) and planet.has("deuterium"): planet["deuterium"]["current"] = float(deu_ov[pname])

func load_sector_data_safe(sector_id: String) -> Dictionary:
	return GameDatabase.load_sector_data(sector_id)

func _to_roman(num: int) -> String:
	var vals := [10,9,5,4,1]; var syms := ["X","IX","V","IV","I"]
	var result := ""; var n := num
	for i in range(vals.size()):
		while n >= vals[i]: result += syms[i]; n -= vals[i]
	return result