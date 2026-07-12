class_name TouchControls
extends Control

const DEBUG_FORCE_SHOW := false

const BUTTON_SIZE  := 84.0
const BUTTON_GAP   := 10.0
const JOYSTICK_R   := 72.0
const EDGE_MARGIN  := 18.0
const FONT_SIZE    := 28

static func should_show() -> bool:
	if DEBUG_FORCE_SHOW:
		return true
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _ready() -> void:
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_build_joysticks()
	_build_left_buttons()
	_build_right_buttons()
	_build_top_buttons()

func _build_joysticks() -> void:
	var m := EDGE_MARGIN
	var d := JOYSTICK_R * 2.0

	var move := TouchJoystick.new()
	move.key_up    = KEY_W
	move.key_down  = KEY_S
	move.key_left  = KEY_A
	move.key_right = KEY_D
	move.stick_radius = JOYSTICK_R
	_place(move, Vector2(0.0, 1.0), m, -(m + d), m + d, -m)
	add_child(move)

	var look := TouchJoystick.new()
	look.key_up    = KEY_UP
	look.key_down  = KEY_DOWN
	look.key_left  = KEY_LEFT
	look.key_right = KEY_RIGHT
	look.stick_radius = JOYSTICK_R
	_place(look, Vector2(1.0, 1.0), -(m + d), -(m + d), -m, -m)
	add_child(look)

func _build_left_buttons() -> void:
	var m  := EDGE_MARGIN
	var d  := JOYSTICK_R * 2.0
	var bs := BUTTON_SIZE
	var bg := BUTTON_GAP

	var r1_b := -(m + d + bg);  var r1_t := r1_b - bs
	var r2_b := r1_t - bg;      var r2_t := r2_b - bs

	var c1_l := m;           var c1_r := m + bs
	var c2_l := m + bs + bg; var c2_r := m + bs + bg + bs

	var btn_rl := _make_btn("\u21BA", "touch.roll_left")
	_place(btn_rl, Vector2(0.0, 1.0), c1_l, r1_t, c1_r, r1_b)
	_connect_hold(btn_rl, KEY_Q)
	add_child(btn_rl)

	var btn_rr := _make_btn("\u21BB", "touch.roll_right")
	_place(btn_rr, Vector2(0.0, 1.0), c2_l, r1_t, c2_r, r1_b)
	_connect_hold(btn_rr, KEY_E)
	add_child(btn_rr)

	var btn_up := _make_btn("\u25B2", "touch.up")
	_place(btn_up, Vector2(0.0, 1.0), c1_l, r2_t, c1_r, r2_b)
	_connect_hold(btn_up, KEY_SPACE)
	add_child(btn_up)

	var btn_dn := _make_btn("\u25BC", "touch.down")
	_place(btn_dn, Vector2(0.0, 1.0), c2_l, r2_t, c2_r, r2_b)
	_connect_hold(btn_dn, KEY_CTRL)
	add_child(btn_dn)

func _build_right_buttons() -> void:
	var m  := EDGE_MARGIN
	var d  := JOYSTICK_R * 2.0
	var bs := BUTTON_SIZE
	var bg := BUTTON_GAP

	var r1_b := -(m + d + bg);  var r1_t := r1_b - bs
	var r2_b := r1_t - bg;      var r2_t := r2_b - bs

	var c1_r := -m;           var c1_l := -m - bs
	var c2_r := -m - bs - bg; var c2_l := -m - bs - bg - bs

	var btn_boost := _make_btn("\u26A1", "touch.boost")
	_place(btn_boost, Vector2(1.0, 1.0), c1_l, r1_t, c1_r, r1_b)
	_connect_hold(btn_boost, KEY_SHIFT)
	add_child(btn_boost)

	var btn_mine := _make_btn("\u26CF", "touch.mine")
	_place(btn_mine, Vector2(1.0, 1.0), c2_l, r1_t, c2_r, r1_b)
	_connect_hold(btn_mine, KEY_M)
	add_child(btn_mine)

	var btn_build := _make_btn("\u25A3", "touch.build")
	_place(btn_build, Vector2(1.0, 1.0), c1_l, r2_t, c1_r, r2_b)
	_connect_tap(btn_build, KEY_B)
	add_child(btn_build)

func _build_top_buttons() -> void:
	var m  := EDGE_MARGIN
	var bs := BUTTON_SIZE
	var bg := BUTTON_GAP

	var btn_fc := _make_btn("\u25CE", "touch.free_cam")
	_place(btn_fc, Vector2(1.0, 0.0), -(m + bs), m, -m, m + bs)
	_connect_tap(btn_fc, KEY_F10)
	add_child(btn_fc)

	var btn_map := _make_btn("\u229E", "touch.map")
	_place(btn_map, Vector2(1.0, 0.0), -(m + bs * 2.0 + bg), m, -(m + bs + bg), m + bs)
	_connect_tap(btn_map, KEY_TAB)
	add_child(btn_map)

func _make_btn(symbol: String, locale_key: String) -> Button:
	var btn := Button.new()
	btn.text = symbol
	btn.tooltip_text = Locale.t(locale_key)
	btn.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	btn.focus_mode = Control.FOCUS_NONE
	btn.modulate   = Color(1, 1, 1, 0.80)
	btn.add_theme_font_size_override("font_size", FONT_SIZE)
	Locale.language_changed.connect(
		func(_lang: String) -> void: btn.tooltip_text = Locale.t(locale_key)
	)
	return btn

func _connect_hold(btn: Button, key: Key) -> void:
	btn.button_down.connect(func() -> void: _send_key(key, true))
	btn.button_up.connect(  func() -> void: _send_key(key, false))

func _connect_tap(btn: Button, key: Key) -> void:
	btn.pressed.connect(func() -> void: _tap_key(key))

func _tap_key(key: Key) -> void:
	_send_key(key, true)
	get_tree().create_timer(0.05).timeout.connect(
		func() -> void: _send_key(key, false)
	)

func _place(ctrl: Control, anchor_pt: Vector2,
		l: float, t: float, r: float, b: float) -> void:
	ctrl.anchor_left   = anchor_pt.x
	ctrl.anchor_right  = anchor_pt.x
	ctrl.anchor_top    = anchor_pt.y
	ctrl.anchor_bottom = anchor_pt.y
	ctrl.offset_left   = l
	ctrl.offset_top    = t
	ctrl.offset_right  = r
	ctrl.offset_bottom = b

static func _send_key(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)
