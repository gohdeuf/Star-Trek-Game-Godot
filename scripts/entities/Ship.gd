class_name Ship
extends Node3D

const DEFAULT_SPEED          := 150.0
const DEFAULT_ROTATION_SPEED := 100.0

@export var speed: float = DEFAULT_SPEED
@export var rotation_speed_deg: float = DEFAULT_ROTATION_SPEED

func _ready() -> void:
	_build_model()
	global_position = GameDatabase.player_position

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_rotation(delta)

func _handle_movement(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	if Input.is_action_pressed("move_up"):      dir += transform.basis.y
	if Input.is_action_pressed("move_down"):    dir -= transform.basis.y
	if dir.length() > 0.0:
		global_position += dir.normalized() * speed * delta

func _handle_rotation(delta: float) -> void:
	var rot := deg_to_rad(rotation_speed_deg * delta)
	if Input.is_action_pressed("pitch_up"):   rotate_object_local(Vector3.RIGHT,   rot)
	if Input.is_action_pressed("pitch_down"): rotate_object_local(Vector3.RIGHT,  -rot)
	if Input.is_action_pressed("yaw_left"):   rotate_object_local(Vector3.UP,      rot)
	if Input.is_action_pressed("yaw_right"):  rotate_object_local(Vector3.UP,     -rot)
	if Input.is_action_pressed("roll_left"):  rotate_object_local(Vector3.FORWARD, rot)
	if Input.is_action_pressed("roll_right"): rotate_object_local(Vector3.FORWARD,-rot)

func _build_model() -> void:
	var saucer := MeshInstance3D.new()
	var saucer_mesh := SphereMesh.new()
	saucer_mesh.radius = 4.0
	saucer_mesh.height = 1.5
	saucer.mesh = saucer_mesh
	saucer.position = Vector3(0, 0.5, 0)
	saucer.scale = Vector3(1.0, 0.25, 1.0)
	add_child(saucer)

	var hull := MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(1.2, 1.0, 5.0)
	hull.mesh = hull_mesh
	hull.position = Vector3(0, -0.5, -3.0)
	add_child(hull)

	for side in [-1, 1]:
		var nacelle := MeshInstance3D.new()
		var nacelle_mesh := CylinderMesh.new()
		nacelle_mesh.top_radius    = 0.5
		nacelle_mesh.bottom_radius = 0.5
		nacelle_mesh.height        = 5.0
		nacelle.mesh = nacelle_mesh
		nacelle.rotation_degrees = Vector3(90, 0, 0)
		nacelle.position = Vector3(side * 2.5, 0.0, -3.5)
		add_child(nacelle)

		var glow := MeshInstance3D.new()
		var glow_mesh := SphereMesh.new()
		glow_mesh.radius = 0.5
		glow_mesh.height = 1.0
		glow.mesh = glow_mesh
		var glow_mat := StandardMaterial3D.new()
		glow_mat.emission_enabled          = true
		glow_mat.emission                  = Color(0.6, 0.8, 1.0)
		glow_mat.emission_energy_multiplier = 3.0
		glow.material_override = glow_mat
		glow.position = Vector3(side * 2.5, 0.0, -6.0)
		add_child(glow)

	var deflector := MeshInstance3D.new()
	var deflector_mesh := SphereMesh.new()
	deflector_mesh.radius = 0.6
	deflector_mesh.height = 1.2
	deflector.mesh = deflector_mesh
	var deflector_mat := StandardMaterial3D.new()
	deflector_mat.albedo_color = Color(1.0, 0.4, 0.2)
	deflector.material_override = deflector_mat
	deflector.position = Vector3(0, -0.5, -5.5)
	add_child(deflector)
