class_name AntimatterFactoryBig
extends Node3D
# Grosse Antimaterie-Fabrik.
# Produktion: 5× staerker als die kleine, braucht mehr Leistung + Deuterium.

const AM_BASE_RATE   := 1.0    # AM/Sek bei voller Leistung + 1x Sternbonus
const REQUIRED_POWER := 150.0
const FULL_POWER     := 300.0
const POWER_RANGE    := 300.0
const AM_DEU_COST    := 2.5
const MAX_STAR_BONUS := 3.0

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
	mat_silver.albedo_color = Color(0.55, 0.6, 0.7); mat_silver.metallic = 0.85

	# Vier Reaktions-Zylinder
	for i in range(4):
		var angle: float = float(i) * PI * 0.5
		var cyl := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 10.0
		cyl.mesh = cm; cyl.material_override = mat_silver
		cyl.position = Vector3(cos(angle) * 3.0, 0.0, sin(angle) * 3.0); add_child(cyl)

	# Verbindungsring
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = 2.5; tm.outer_radius = 3.5; ring.mesh = tm
	ring.material_override = mat_silver; add_child(ring)

	# Obere + untere Abschlussplatten
	for y in [-4.5, 4.5]:
		var cap := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(9.0, 0.5, 9.0); cap.mesh = bm
		cap.material_override = mat_silver; cap.position.y = y; add_child(cap)

	# Grosser Reaktionskammer-Kern
	var chamber := MeshInstance3D.new()
	var csm := SphereMesh.new(); csm.radius = 1.8; csm.height = 3.6; chamber.mesh = csm
	_chamber_mat = StandardMaterial3D.new()
	_chamber_mat.albedo_color = Color(0.2, 0.0, 1.0)
	_chamber_mat.emission_enabled = true; _chamber_mat.emission = Color(0.3, 0.0, 1.0)
	_chamber_mat.emission_energy_multiplier = 0.5
	chamber.material_override = _chamber_mat; add_child(chamber)

	_chamber_light = OmniLight3D.new()
	_chamber_light.light_color = Color(0.3, 0.0, 1.0)
	_chamber_light.omni_range = 50.0; _chamber_light.light_energy = 0.5
	add_child(_chamber_light)

func _process(delta: float) -> void:
	_pulse_time += delta
	var power: float      = _find_nearby_power()
	var star_bonus: float = AntimatterFactorySmall._get_star_proximity_bonus(global_position)
	_active = (power >= REQUIRED_POWER and star_bonus > 0.0 and
		GameDatabase.get_resource("deuterium") >= 10)

	if _active:
		var efficiency: float = clamp(power / FULL_POWER, 0.0, 1.0)
		var am_rate: float    = AM_BASE_RATE * efficiency * star_bonus
		var deu_rate: float   = am_rate * AM_DEU_COST
		_deu_debt += deu_rate * delta
		if _deu_debt >= 1.0:
			var to_spend: int = int(_deu_debt); _deu_debt -= float(to_spend)
			if not GameDatabase.spend_resource("deuterium", to_spend):
				_active = false; return
		GameDatabase.add_resource("antimatter", am_rate * delta)

	var glow: float = (2.5 + sin(_pulse_time * 2.5) * 1.2) if _active else 0.3
	if _chamber_mat  != null: _chamber_mat.emission_energy_multiplier  = glow
	if _chamber_light != null: _chamber_light.light_energy = glow * 0.6

func _find_nearby_power() -> float:
	var total: float = 0.0
	for node in get_tree().get_nodes_in_group("fusion_cores"):
		if not node is Node3D: continue
		if global_position.distance_to(node.global_position) <= POWER_RANGE:
			total += (node as FusionCore).power_output
	return total
