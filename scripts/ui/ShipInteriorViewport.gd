class_name ShipInteriorViewport
extends Control

var _viewport: SubViewport = null
var _camera: Camera3D = null
var _active: bool = false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1024, 768)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.7, 0.2)
	_camera.rotation_degrees = Vector3(0, 180, 0)
	_viewport.add_child(_camera)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.12)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	var label := Label.new()
	label.text = "Interior view"
	label.position = Vector2(16, 16)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_ship_interior"):
		_active = not _active
		visible = _active
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _active or get_parent() == null: return
	var ship: Node3D = get_parent().get_node_or_null("Ship")
	if ship == null: return
	_camera.global_position = ship.global_position + Vector3(0, 1.7, 0.2)
	_camera.global_rotation = ship.global_rotation
