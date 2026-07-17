class_name Ship
extends Node3D

const DEFAULT_SPEED          := 150.0
const DEFAULT_ROTATION_SPEED := 100.0
const BOOST_MULTIPLIER       := 3.0

@export var speed: float              = DEFAULT_SPEED
@export var rotation_speed_deg: float = DEFAULT_ROTATION_SPEED

var _weapon_system: WeaponSystem = null
var _warp_drive:    WarpDrive    = null
var _crew_system:   CrewSystem   = null

func _ready() -> void:
	_build_model()
	global_position = GameDatabase.player_position
	quaternion      = GameDatabase.player_rotation

func init_systems(weapon_sys: WeaponSystem, warp_drv: WarpDrive, crew_sys: CrewSystem) -> void:
	_weapon_system = weapon_sys; _warp_drive = warp_drv; _crew_system = crew_sys

func _physics_process(delta: float) -> void:
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
	var saucer := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 4.0; sm.height = 1.5
	saucer.mesh = sm; saucer.position = Vector3(0,0.5,0); saucer.scale = Vector3(1,0.25,1); add_child(saucer)
	var hull := MeshInstance3D.new()
	var hm := BoxMesh.new(); hm.size = Vector3(1.2,1.0,5.0)
	hull.mesh = hm; hull.position = Vector3(0,-0.5,-3.0); add_child(hull)
	for side in [-1, 1]:
		var nac := MeshInstance3D.new()
		var nm := CylinderMesh.new(); nm.top_radius=0.5; nm.bottom_radius=0.5; nm.height=5.0
		nac.mesh=nm; nac.rotation_degrees=Vector3(90,0,0); nac.position=Vector3(side*2.5,0,-3.5); add_child(nac)
		var glow := MeshInstance3D.new()
		var gm := SphereMesh.new(); gm.radius=0.5; gm.height=1.0; glow.mesh=gm
		var gmat := StandardMaterial3D.new()
		gmat.emission_enabled=true; gmat.emission=Color(0.6,0.8,1.0); gmat.emission_energy_multiplier=3.0
		glow.material_override=gmat; glow.position=Vector3(side*2.5,0.0,-6.0); add_child(glow)
	var defl := MeshInstance3D.new()
	var dm := SphereMesh.new(); dm.radius=0.6; dm.height=1.2; defl.mesh=dm
	var dmat := StandardMaterial3D.new(); dmat.albedo_color=Color(1.0,0.4,0.2)
	defl.material_override=dmat; defl.position=Vector3(0,-0.5,-5.5); add_child(defl)
