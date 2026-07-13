class_name TouchControls
extends Control
const DEBUG_FORCE_SHOW := false
const BUTTON_SIZE := 84.0; const BUTTON_GAP := 10.0; const JOYSTICK_R := 72.0
const EDGE_MARGIN := 18.0; const FONT_SIZE := 28
static func should_show() -> bool:
	return DEBUG_FORCE_SHOW or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
func _ready() -> void:
	anchor_right = 1.0; anchor_bottom = 1.0; mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_joysticks(); _build_left_buttons(); _build_right_buttons(); _build_top_buttons()
func _build_joysticks() -> void:
	var m := EDGE_MARGIN; var d := JOYSTICK_R * 2.0
	var mv := TouchJoystick.new(); mv.key_up=KEY_W; mv.key_down=KEY_S; mv.key_left=KEY_A; mv.key_right=KEY_D; mv.stick_radius=JOYSTICK_R
	_place(mv, Vector2(0,1), m, -(m+d), m+d, -m); add_child(mv)
	var lk := TouchJoystick.new(); lk.key_up=KEY_UP; lk.key_down=KEY_DOWN; lk.key_left=KEY_LEFT; lk.key_right=KEY_RIGHT; lk.stick_radius=JOYSTICK_R
	_place(lk, Vector2(1,1), -(m+d), -(m+d), -m, -m); add_child(lk)
func _build_left_buttons() -> void:
	var m:=EDGE_MARGIN; var d:=JOYSTICK_R*2.0; var bs:=BUTTON_SIZE; var bg:=BUTTON_GAP
	var r1b:=-(m+d+bg); var r1t:=r1b-bs; var r2b:=r1t-bg; var r2t:=r2b-bs
	var c1l:=m; var c1r:=m+bs; var c2l:=m+bs+bg; var c2r:=m+bs+bg+bs
	var brl:=_make_btn("\u21BA","touch.roll_left"); _place(brl,Vector2(0,1),c1l,r1t,c1r,r1b); _connect_hold(brl,KEY_Q); add_child(brl)
	var brr:=_make_btn("\u21BB","touch.roll_right"); _place(brr,Vector2(0,1),c2l,r1t,c2r,r1b); _connect_hold(brr,KEY_E); add_child(brr)
	var bu:=_make_btn("\u25B2","touch.up"); _place(bu,Vector2(0,1),c1l,r2t,c1r,r2b); _connect_hold(bu,KEY_SPACE); add_child(bu)
	var bd:=_make_btn("\u25BC","touch.down"); _place(bd,Vector2(0,1),c2l,r2t,c2r,r2b); _connect_hold(bd,KEY_CTRL); add_child(bd)
func _build_right_buttons() -> void:
	var m:=EDGE_MARGIN; var d:=JOYSTICK_R*2.0; var bs:=BUTTON_SIZE; var bg:=BUTTON_GAP
	var r1b:=-(m+d+bg); var r1t:=r1b-bs; var r2b:=r1t-bg; var r2t:=r2b-bs
	var c1r:=-m; var c1l:=-m-bs; var c2r:=-m-bs-bg; var c2l:=-m-bs-bg-bs
	var bb:=_make_btn("\u26A1","touch.boost"); _place(bb,Vector2(1,1),c1l,r1t,c1r,r1b); _connect_hold(bb,KEY_SHIFT); add_child(bb)
	var bm:=_make_btn("\u26CF","touch.mine"); _place(bm,Vector2(1,1),c2l,r1t,c2r,r1b); _connect_hold(bm,KEY_M); add_child(bm)
	var bbuild:=_make_btn("\u25A3","touch.build"); _place(bbuild,Vector2(1,1),c1l,r2t,c1r,r2b); _connect_tap(bbuild,KEY_B); add_child(bbuild)
func _build_top_buttons() -> void:
	var m:=EDGE_MARGIN; var bs:=BUTTON_SIZE; var bg:=BUTTON_GAP
	var bfc:=_make_btn("\u25CE","touch.free_cam"); _place(bfc,Vector2(1,0),-(m+bs),m,-m,m+bs); _connect_tap(bfc,KEY_F10); add_child(bfc)
	var bmap:=_make_btn("\u229E","touch.map"); _place(bmap,Vector2(1,0),-(m+bs*2.0+bg),m,-(m+bs+bg),m+bs); _connect_tap(bmap,KEY_TAB); add_child(bmap)
func _make_btn(symbol: String, locale_key: String) -> Button:
	var btn := Button.new(); btn.text=symbol; btn.tooltip_text=Locale.t(locale_key)
	btn.custom_minimum_size=Vector2(BUTTON_SIZE,BUTTON_SIZE); btn.focus_mode=Control.FOCUS_NONE
	btn.modulate=Color(1,1,1,0.80); btn.add_theme_font_size_override("font_size",FONT_SIZE)
	Locale.language_changed.connect(func(_lang:String)->void: btn.tooltip_text=Locale.t(locale_key)); return btn
func _connect_hold(btn: Button, key: Key) -> void:
	btn.button_down.connect(func()->void: _send_key(key,true)); btn.button_up.connect(func()->void: _send_key(key,false))
func _connect_tap(btn: Button, key: Key) -> void:
	btn.pressed.connect(func()->void: _tap_key(key))
func _tap_key(key: Key) -> void:
	_send_key(key,true); get_tree().create_timer(0.05).timeout.connect(func()->void: _send_key(key,false))
func _place(ctrl: Control, ap: Vector2, l:float, t:float, r:float, b:float) -> void:
	ctrl.anchor_left=ap.x; ctrl.anchor_right=ap.x; ctrl.anchor_top=ap.y; ctrl.anchor_bottom=ap.y
	ctrl.offset_left=l; ctrl.offset_top=t; ctrl.offset_right=r; ctrl.offset_bottom=b
static func _send_key(keycode: Key, pressed: bool) -> void:
	var ev:=InputEventKey.new(); ev.physical_keycode=keycode; ev.pressed=pressed; Input.parse_input_event(ev)
