class_name AntimatterFactorySmall
extends Node3D
# Kleine Antimaterie-Fabrik.
# Produktion: AM_BASE_RATE * power_efficiency * star_proximity_bonus [AM/Sek]
# Benoetigt: >= REQUIRED_POWER Leistung von FusionCores in POWER_RANGE.
# Kostet: AM_DEU_COST Deuterium pro produzierter AM-Einheit.
# Keine Produktion ausserhalb einer Sternen-SOI (star_bonus == 0).

const AM_BASE_RATE    := 0.2    # AM/Sek bei voller Leistung + 1x Sternbonus
const REQUIRED_POWER  := 50.0   # Mindest-Leistungsbedarf
const FULL_POWER      := 100.0  # Leistung fuer 100% Effizienz
const POWER_RANGE     := 200.0  # Suchradius fuer FusionCores
const AM_DEU_COST     := 2.5    # Deuterium pro AM-Einheit
const MAX_STAR_BONUS  := 3.0    # Max. Bonus dicht am Stern (1.0 am SOI-Rand)

var _deu_debt:   float = 0.0
var _pulse_time: float = 0.0
var _chamber_light: OmniLight3D = null
var _chamber_mat:   StandardMaterial3D = null
var _active: bool = false

func _ready() -> void:
	add_to_group("stations")
	add_to_group("am_factories")
	_build_visual()

func _build_visual() -> void:
	var mat_silver := StandardMaterial3D.new()
	mat_silver.albedo_color = Color(0.6, 0.65, 0.7); mat_silver.metallic = 0.85

	# Zwei parallele Reaktions-Zylinder (Materie / Antimaterie)
	for side in [-1, 1]:
		var cyl := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 0.7; cm.bottom_radius = 0.7; cm.height = 6.0
		cyl.mesh = cm; cyl.material_override = mat_silver
		cyl.position = Vector3(float(side) * 1.8, 0.0, 0.0); add_child(cyl)

	# Verbindungsbruecken
	for z in [-2.0, 0.0, 2.0]:
		var bridge := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(4.2, 0.5, 0.6); bridge.mesh = bm
		bridge.material_override = mat_silver; bridge.position = Vector3(0, 0, z); add_child(bridge)

	# Zentraler Reaktionskammer-Kern (leuchtet bei Produktion)
	var chamber := MeshInstance3D.new()
	var csm := SphereMesh.new(); csm.radius = 0.9; csm.height = 1.8; chamber.mesh = csm
	_chamber_mat = StandardMaterial3D.new()
	_chamber_mat.albedo_color = Color(0.0, 0.9, 1.0)
	_chamber_mat.emission_enabled = true; _chamber_mat.emission = Color(0.0, 0.8, 1.0)
	_chamber_mat.emission_energy_multiplier = 0.5
	chamber.material_override = _chamber_mat; add_child(chamber)

	_chamber_light = OmniLight3D.new()
	_chamber_light.light_color = Color(0.0, 0.8, 1.0)
	_chamber_light.omni_range = 25.0; _chamber_light.light_energy = 0.3
	add_child(_chamber_light)

func _process(delta: float) -> void:
	_pulse_time += delta
	var power: float   = _find_nearby_power()
	var star_bonus: float = _get_star_proximity_bonus(global_position)
	_active = (power >= REQUIRED_POWER and star_bonus > 0.0 and
		GameDatabase.get_resource("deuterium") >= 5)

	if _active:
		var efficiency: float  = clamp(power / FULL_POWER, 0.0, 1.0)
		var am_rate: float     = AM_BASE_RATE * efficiency * star_bonus
		var deu_rate: float    = am_rate * AM_DEU_COST
		_deu_debt += deu_rate * delta
		if _deu_debt >= 1.0:
			var to_spend: int = int(_deu_debt); _deu_debt -= float(to_spend)
			if not GameDatabase.spend_resource("deuterium", to_spend):
				_active = false; return
		GameDatabase.add_resource("antimatter", am_rate * delta)

	# Visuelles Feedback
	var glow: float = (1.5 + sin(_pulse_time * 3.0) * 0.8) if _active else 0.2
	if _chamber_mat  != null: _chamber_mat.emission_energy_multiplier  = glow
	if _chamber_light != null: _chamber_light.light_energy = glow * 0.5

func _find_nearby_power() -> float:
	var total: float = 0.0
	for node in get_tree().get_nodes_in_group("fusion_cores"):
		if not node is Node3D: continue
		if global_position.distance_to(node.global_position) <= POWER_RANGE:
			total += (node as FusionCore).power_output
	return total

static func _get_star_proximity_bonus(pos: Vector3) -> float:
	var best: float = 0.0
	for sys in SectorGenerator.get_cached_systems():
		var dist: float = pos.distance_to(sys["position"])
		var soi: float  = sys["sphere_of_influence"]
		if dist > soi: continue
		var norm: float   = 1.0 - clamp(dist / soi, 0.0, 1.0)
		var bonus: float  = 1.0 + norm * (MAX_STAR_BONUS - 1.0)
		if bonus > best: best = bonus
	return best
