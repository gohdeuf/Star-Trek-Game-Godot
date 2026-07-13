class_name TouchJoystick
extends Control
@export var key_up: Key = KEY_NONE; @export var key_down: Key = KEY_NONE
@export var key_left: Key = KEY_NONE; @export var key_right: Key = KEY_NONE
@export var stick_radius: float = 70.0; @export var dead_zone: float = 0.25
var _active_index: int = -2; var _knob_offset: Vector2 = Vector2.ZERO; var _held_keys: Dictionary = {}
func _ready() -> void:
	custom_minimum_size = Vector2(stick_radius * 2.0, stick_radius * 2.0); mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_index == -2: _active_index = event.index; _update_from_local(event.position)
		elif not event.pressed and event.index == _active_index: _active_index = -2; _reset()
	elif event is InputEventScreenDrag:
		if event.index == _active_index: _update_from_local(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _active_index == -2: _active_index = -1; _update_from_local(event.position)
		elif not event.pressed and _active_index == -1: _active_index = -2; _reset()
	elif event is InputEventMouseMotion and _active_index == -1: _update_from_local(event.position)
func _update_from_local(local_pos: Vector2) -> void:
	var center := size / 2.0; var offset := local_pos - center; var dist := offset.length()
	if dist > stick_radius: offset = offset.normalized() * stick_radius; dist = stick_radius
	_knob_offset = offset; queue_redraw()
	var mag := dist / stick_radius; var norm := offset / stick_radius
	_set_key_state(key_up,    mag >= dead_zone and norm.y < -0.35)
	_set_key_state(key_down,  mag >= dead_zone and norm.y >  0.35)
	_set_key_state(key_left,  mag >= dead_zone and norm.x < -0.35)
	_set_key_state(key_right, mag >= dead_zone and norm.x >  0.35)
func _reset() -> void:
	_knob_offset = Vector2.ZERO; queue_redraw()
	_set_key_state(key_up, false); _set_key_state(key_down, false)
	_set_key_state(key_left, false); _set_key_state(key_right, false)
func _set_key_state(key: Key, pressed: bool) -> void:
	if key == KEY_NONE: return
	if _held_keys.get(key, false) == pressed: return
	_held_keys[key] = pressed; _send_key(key, pressed)
func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE: _reset()
func _draw() -> void:
	var c := size / 2.0; var kr := stick_radius
	draw_circle(c, kr, Color(1,1,1,0.10)); draw_arc(c, kr, 0.0, TAU, 40, Color(1,1,1,0.50), 2.5)
	var tick := kr * 0.12
	for angle in [0.0, PI*0.5, PI, PI*1.5]:
		var tip := c + Vector2(cos(angle),sin(angle))*(kr-4.0); var base := c + Vector2(cos(angle),sin(angle))*(kr-4.0-tick)
		draw_line(base, tip, Color(1,1,1,0.30), 2.0)
	var kr2 := kr * 0.40; draw_circle(c+_knob_offset, kr2, Color(1,1,1,0.55)); draw_arc(c+_knob_offset, kr2, 0.0, TAU, 24, Color(1,1,1,0.80), 2.0)
static func _send_key(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new(); ev.physical_keycode = keycode; ev.pressed = pressed; Input.parse_input_event(ev)
