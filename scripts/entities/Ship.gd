class_name Ship
extends Node3D

# ── Maßstab ──────────────────────────────────────────────────────────────────
# Erde = 10.0 Units = 6371 km  →  1 Unit ≈ 637 m
# Enterprise-D Saucer-Radius real ≈ 210 m = 0.33 Units
# Spielwert 0.03 = ~90× real  →  1/333 des Erddurchmessers, klar sichtbar
const SAUCER_RADIUS := 0.03

const DEFAULT_SPEED          := 150.0
const DEFAULT_ROTATION_SPEED := 100.0
const BOOST_MULTIPLIER       := 3.0

@export var speed: float              = DEFAULT_SPEED
@export var rotation_speed_deg: float = DEFAULT_ROTATION_SPEED

var _weapon_system: WeaponSystem = null
var _warp_drive:    WarpDrive    = null
var _crew_system:   CrewSystem   = null

var _orbit_carrier:    Node3D  = null
var _last_carrier_pos: Vector3 = Vector3.ZERO

func set_orbit_carrier(body: Node3D) -> void:
	_orbit_carrier = body
	if body != null and is_instance_valid(body):
		_last_carrier_pos = body.global_position

func _apply_orbit_carry() -> void:
	if _warp_drive != null and _warp_drive.is_active(): return
	if _orbit_carrier == null or not is_instance_valid(_orbit_carrier):
		_orbit_carrier = null; return
	var body_delta: Vector3 = _orbit_carrier.global_position - _last_carrier_pos
	global_position        += body_delta
	_last_carrier_pos       = _orbit_carrier.global_position

func _ready() -> void:
	_build_model()
	global_position = GameDatabase.player_position
	quaternion      = GameDatabase.player_rotation

func init_systems(weapon_sys: WeaponSystem, warp_drv: WarpDrive, crew_sys: CrewSystem) -> void:
	_weapon_system = weapon_sys; _warp_drive = warp_drv; _crew_system = crew_sys

func _physics_process(delta: float) -> void:
	_apply_orbit_carry()
	if _crew_system != null and _crew_system.emergency_ai_active: return
	if _warp_drive  != null and _warp_drive.is_active():          return
	if StationEditor.is_editor_open:                              return
	_handle_movement(delta); _handle_rotation(delta)

func _handle_movement(delta: float) -> void:
	var speed_mult: float = 1.0
	if _crew_system != null: speed_mult = _crew_system.speed_modifier
	var boost: float = BOOST_MULTIPLIER if Input.is_action_pressed("boost") else 1.0
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	if Input.is_action_pressed("move_up"):      dir += transform.basis.y
	if Input.is_action_pressed("move_down"):    dir -= transform.basis.y
	if dir.length() > 0.0:
		global_position += dir.normalized() * speed * speed_mult * boost * delta

func _handle_rotation(delta: float) -> void:
	var rot_mult: float = 1.0
	if _crew_system != null: rot_mult = _crew_system.rotation_modifier
	var rot: float = deg_to_rad(rotation_speed_deg * rot_mult * delta)
	if Input.is_action_pressed("pitch_up"):   rotate_object_local(Vector3.RIGHT,    rot)
	if Input.is_action_pressed("pitch_down"): rotate_object_local(Vector3.RIGHT,   -rot)
	if Input.is_action_pressed("yaw_left"):   rotate_object_local(Vector3.UP,       rot)
	if Input.is_action_pressed("yaw_right"):  rotate_object_local(Vector3.UP,      -rot)
	if Input.is_action_pressed("roll_left"):  rotate_object_local(Vector3.FORWARD,  rot)
	if Input.is_action_pressed("roll_right"): rotate_object_local(Vector3.FORWARD, -rot)

func _build_model() -> void:
	var s := SAUCER_RADIUS

	# Saucer-Disk
	var saucer := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = s; sm.height = s * 0.5
	saucer.mesh  = sm
	saucer.position = Vector3(0.0, s * 0.12, 0.0)
	saucer.scale    = Vector3(1.0, 0.22, 1.0)
	add_child(saucer)

	# Verbindungs-Hull
	var hull := MeshInstance3D.new()
	var hm := BoxMesh.new(); hm.size = Vector3(s * 0.35, s * 0.28, s * 1.5)
	hull.mesh = hm; hull.position = Vector3(0.0, -s * 0.12, -s * 0.9); add_child(hull)

	# Gondeln + Triebwerks-Glow
	for side in [-1, 1]:
		var nac := MeshInstance3D.new()
		var nm  := CylinderMesh.new()
		nm.top_radius = s * 0.13; nm.bottom_radius = s * 0.13; nm.height = s * 1.6
		nac.mesh = nm; nac.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		nac.position = Vector3(float(side) * s * 0.72, 0.0, -s * 1.1); add_child(nac)

		var glow := MeshInstance3D.new()
		var gm   := SphereMesh.new(); gm.radius = s * 0.14; gm.height = s * 0.28
		glow.mesh = gm
		var gmat := StandardMaterial3D.new()
		gmat.emission_enabled           = true
		gmat.emission                   = Color(0.6, 0.8, 1.0)
		gmat.emission_energy_multiplier = 4.0
		glow.material_override = gmat
		glow.position = Vector3(float(side) * s * 0.72, 0.0, -s * 1.9); add_child(glow)

	# Deflektorschüssel
	var defl := MeshInstance3D.new()
	var dm   := SphereMesh.new(); dm.radius = s * 0.18; dm.height = s * 0.36
	defl.mesh = dm
	var dmat := StandardMaterial3D.new(); dmat.albedo_color = Color(1.0, 0.45, 0.15)
	defl.material_override = dmat
	defl.position = Vector3(0.0, -s * 0.12, -s * 1.72); add_child(defl)