class_name SOINotification
extends Control
const DISPLAY_TIME := 3.5; const FADE_TIME := 0.9
var _label: Label; var _timer: float = 0.0; var _fading: bool = false
func _ready() -> void:
	anchor_right = 1.0; anchor_bottom = 1.0; mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.anchor_left = 0.0; _label.anchor_right = 1.0; _label.anchor_top = 0.0; _label.anchor_bottom = 0.0
	_label.offset_top = 58; _label.offset_bottom = 96
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.35))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label); visible = false
func show_message(text: String) -> void:
	_label.text = text; _label.modulate.a = 1.0; visible = true; _timer = 0.0; _fading = false
func _process(delta: float) -> void:
	if not visible: return
	_timer += delta
	if not _fading and _timer >= DISPLAY_TIME: _fading = true; _timer = 0.0
	if _fading:
		_label.modulate.a = maxf(0.0, 1.0 - (_timer / FADE_TIME))
		if _timer >= FADE_TIME: visible = false
