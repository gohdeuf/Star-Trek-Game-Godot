class_name CameraRig
extends Node3D

@export var follow_distance: float           = 0.26
@export var follow_height:   float           = 0.10
@export var follow_lerp_speed: float         = 5.0
@export var free_cam_base_speed: float       = 50.0
@export var free_cam_boost_multiplier: float = 10.0
@export var mouse_sensitivity: float         = 0.15

var target:           Node3D    = null
var camera:           Camera3D
var free_cam_enabled: bool      = false
var _free_cam_speed:  float

# BridgeView als Node3D typisiert (parse-safe), wird per is/as zur Laufzeit gecasted
var _bridge_view: Node3D = null

func _ready() -> void:
	camera = Camera3D.new(); add_child(camera); camera.current = true
	_free_cam_speed = free_cam_base_speed

func set_target(node: Node3D)     -> void: target       = node
func set_bridge_view(bv: Node3D)  -> void: _bridge_view = bv

func _bridge_is_active() -> bool:
	if _bridge_view == null or not (_bridge_view is BridgeView): return false
	return (_bridge_view as BridgeView).is_active

func _unhandled_input(event: InputEvent) -> void:
	# Brücken-Toggle hat Vorrang
	if event.is_action_pressed("toggle_bridge"):
		_toggle_bridge(); return

	# Alle weiteren Inputs ignorieren wenn Brücke aktiv
	if _bridge_is_active(): return

	if event.is_action_pressed("toggle_free_cam"):
		free_cam_enabled = not free_cam_enabled
	if not free_cam_enabled: return

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_free_cam_speed *= 1.2
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_free_cam_speed = max(1.0, _free_cam_speed / 1.2)

func _toggle_bridge() -> void:
	if _bridge_view == null or not (_bridge_view is BridgeView): return
	var bv: BridgeView = _bridge_view as BridgeView
	if bv.is_active:
		bv.deactivate(camera)
	else:
		free_cam_enabled = false   # Freie Kamera deaktivieren
		bv.activate(camera)

func _process(delta: float) -> void:
	if _bridge_is_active(): return   # Brückenkamera steuert sich selbst
	if free_cam_enabled: _process_free_cam(delta)
	else:                _process_follow_cam(delta)

func _process_follow_cam(delta: float) -> void:
	if target == null: return
	var desired_pos: Vector3 = target.global_position \
		+ target.transform.basis.z * follow_distance \
		+ target.transform.basis.y * follow_height
	global_position = global_position.lerp(desired_pos, delta * follow_lerp_speed)

	# ── Gimbal-Lock-Fix ─────────────────────────────────────────────────────
	# look_at() versagt wenn Up-Vektor parallel zum Blickvektor ist (z.B. Polflug).
	# Fallback: Schiff-Seitenachse als Up wenn Schiff-Oben zu parallel zum Blick.
	var to_target: Vector3 = target.global_position - global_position
	if to_target.length() > 0.0001:
		var up: Vector3 = target.transform.basis.y
		if abs(up.dot(to_target.normalized())) > 0.92:
			# Schiff zeigt (fast) direkt zu/von der Kamera → Seitenachse als Notfall-Up
			up = target.transform.basis.x
		look_at(target.global_position, up)
	rotation.z = target.rotation.z

func _process_free_cam(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += transform.basis.x
	if Input.is_action_pressed("move_up"):      dir += Vector3.UP
	if Input.is_action_pressed("move_down"):    dir += Vector3.DOWN
	if dir.length() > 0.0:
		var spd := _free_cam_speed \
			* (free_cam_boost_multiplier if Input.is_action_pressed("boost") else 1.0)
		global_position += dir.normalized() * spd * delta