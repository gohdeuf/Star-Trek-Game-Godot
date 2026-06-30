class_name CameraRig
extends Node3D
# Kamera-System (siehe Referenz Abschnitt 10).
# Standardmodus "follow": lerpt hinter das Schiff, schaut aufs Schiff,
# uebernimmt Roll. F10 schaltet auf freie Kamera (RMB+Maus = Drehen,
# WASD/Space/Strg = Fliegen, Shift = 10x Boost, Scroll = Grundgeschwindigkeit).

@export var follow_distance: float = 15.0
@export var follow_height: float = 5.0
@export var follow_lerp_speed: float = 4.0
@export var free_cam_base_speed: float = 50.0
@export var free_cam_boost_multiplier: float = 10.0
@export var mouse_sensitivity: float = 0.15

var target: Node3D
var camera: Camera3D
var free_cam_enabled := false
var _free_cam_speed: float

func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	_free_cam_speed = free_cam_base_speed

func set_target(node: Node3D) -> void:
	target = node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_free_cam"):
		free_cam_enabled = not free_cam_enabled

	if not free_cam_enabled:
		return

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_free_cam_speed *= 1.2
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_free_cam_speed = max(1.0, _free_cam_speed / 1.2)

func _process(delta: float) -> void:
	if free_cam_enabled:
		_process_free_cam(delta)
	else:
		_process_follow_cam(delta)

func _process_follow_cam(delta: float) -> void:
	if target == null:
		return
	var desired_pos: Vector3 = target.global_position \
		+ target.transform.basis.z * follow_distance \
		+ target.transform.basis.y * follow_height
	global_position = global_position.lerp(desired_pos, delta * follow_lerp_speed)
	look_at(target.global_position, target.transform.basis.y)
	rotation.z = target.rotation.z  # Roll vom Schiff uebernehmen

func _process_free_cam(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	if Input.is_action_pressed("move_up"):
		dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		dir += Vector3.DOWN

	if dir.length() > 0.0:
		dir = dir.normalized()
		var current_speed := _free_cam_speed
		if Input.is_action_pressed("boost"):
			current_speed *= free_cam_boost_multiplier
		global_position += dir * current_speed * delta
